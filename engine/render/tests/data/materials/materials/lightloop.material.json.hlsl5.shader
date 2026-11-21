{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4a8331d4c52f4add9385ad09f3cee754aeec6a52a5c8c810972e182590f5426b",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3872[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6283 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _469_fa_camera_pos : packoffset(c0);\n    float4 _469_fa_ambient : packoffset(c1);\n    float4 _469_fa_base_color : packoffset(c2);\n    float4 _469_fa_emissive : packoffset(c3);\n    float4 _469_fa_model_emissive : packoffset(c4);\n    float4 _469_fa_pbr : packoffset(c5);\n    float4 _469_fa_maps : packoffset(c6);\n    float4 _469_fa_fog : packoffset(c7);\n    float4 _469_fa_fog_b : packoffset(c8);\n    float4 _469_fa_fog_c : packoffset(c9);\n    float4 _469_fa_counts : packoffset(c10);\n    float4 _469_fa_env_sky : packoffset(c11);\n    float4 _469_fa_env_horizon : packoffset(c12);\n    float4 _469_fa_time : packoffset(c13);\n    float4 _469_fa_cl_vpx : packoffset(c14);\n    float4 _469_fa_cl_vpy : packoffset(c15);\n    float4 _469_fa_cl_vpw : packoffset(c16);\n    float4 _469_fa_cl_fwd : packoffset(c17);\n    float4 _469_fa_cl_grid : packoffset(c18);\n    float4 _469_fa_cl_info : packoffset(c19);\n    float4 _469_fa_layers_a : packoffset(c20);\n    float4 _469_fa_layers_b : packoffset(c21);\n    float4 _469_fa_layers_c : packoffset(c22);\n    float4 _469_fa_layers_d : packoffset(c23);\n    float4 _469_fa_ct_a : packoffset(c24);\n    float4 _469_fa_ct_b : packoffset(c25);\n    float4 _469_fa_ct_vpx : packoffset(c26);\n    float4 _469_fa_ct_vpy : packoffset(c27);\n    float4 _469_fa_ct_vpw : packoffset(c28);\n    float4 _469_fa_ct_fwd : packoffset(c29);\n    float4 _469_fa_tr_a : packoffset(c30);\n    float4 _469_fa_tr_b : packoffset(c31);\n    float4 _469_fa_probe_sh[9] : packoffset(c32);\n    float4 _469_fa_atlas : packoffset(c41);\n    float4 _469_fa_rpa_tile : packoffset(c42);\n    float4 _469_fa_rpa_pos : packoffset(c43);\n    float4 _469_fa_rpa_bx : packoffset(c44);\n    float4 _469_fa_rpa_by : packoffset(c45);\n    float4 _469_fa_rpa_bz : packoffset(c46);\n    float4 _469_fa_rpb_tile : packoffset(c47);\n    float4 _469_fa_rpb_pos : packoffset(c48);\n    float4 _469_fa_rpb_bx : packoffset(c49);\n    float4 _469_fa_rpb_by : packoffset(c50);\n    float4 _469_fa_rpb_bz : packoffset(c51);\n    float4 _469_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2127_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2127_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2127_fa_shadow_info[4] : packoffset(c20);\n    float4 _2127_fa_shadow_split : packoffset(c24);\n    float4 _2127_fa_shadow_cfg : packoffset(c25);\n    float4 _2127_fa_shadow_bias : packoffset(c26);\n    float4 _2127_fa_shadow_eye : packoffset(c27);\n    float4 _2127_fa_shadow_fwd : packoffset(c28);\n    float4 _2127_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5008_dark : packoffset(c0);\n    float _5008_fa_pad0 : packoffset(c0.y);\n    float _5008_fa_pad1 : packoffset(c0.z);\n    float _5008_fa_pad2 : packoffset(c0.w);\n    float _5008_skyAmount : packoffset(c1);\n    float _5008_fa_pad3 : packoffset(c1.y);\n    float _5008_fa_pad4 : packoffset(c1.z);\n    float _5008_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1398 = _469_fa_cl_info.x < 0.0f;\n    bool _1405;\n    if (!_1398)\n    {\n        _1405 = _469_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    bool _1413;\n    if (!_1405)\n    {\n        _1413 = _469_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1413 = _1405;\n    }\n    bool _1420;\n    if (!_1413)\n    {\n        _1420 = _469_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1420 = _1413;\n    }\n    bool _1427;\n    if (!_1420)\n    {\n        _1427 = _469_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1427 = _1420;\n    }\n    if (_1427)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1437 = float4(world_pos, 1.0f);\n    float _1443 = dot(_469_fa_cl_vpw, _1437);\n    if (!(_1443 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1465 = float2(dot(_469_fa_cl_vpx, _1437), dot(_469_fa_cl_vpy, _1437)) / _1443.xx;\n    int _1469 = int(_469_fa_cl_grid.x);\n    int _1473 = int(_469_fa_cl_grid.y);\n    int param = (int(_469_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_469_fa_cl_fwd.xyz, world_pos) + _469_fa_cl_fwd.w, _469_fa_cl_grid.w) / _469_fa_cl_grid.w) * _469_fa_cl_grid.z)), 0, int(_469_fa_cl_info.y) - 1) * _1473) + clamp(int(floor(((_1465.y * 0.5f) + 0.5f) * _469_fa_cl_grid.y)), 0, _1473 - 1)) * _1469)) + clamp(int(floor(((_1465.x * 0.5f) + 0.5f) * _469_fa_cl_grid.x)), 0, _1469 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1549 = fa_cluster_texel(param);\n    return int2(int(_1549.x), int(_1549.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_469_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4692 = fa_cluster_lookup(param);\n    fa_cl_slot = _4692.x;\n    fa_cl_local = _4692.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5069 = fa_linear_to_srgb(param);\n        c = _5069;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5077 = fa_srgb_to_linear(param_1);\n            c = _5077;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _349;\n    if (i.front_facing)\n    {\n        _349 = i.world_normal;\n    }\n    else\n    {\n        _349 = -i.world_normal;\n    }\n    float3 _373 = normalize(i.world_tangent.xyz - (_349 * dot(_349, i.world_tangent.xyz)));\n    float3 _401 = normalize(((_373 * m.x) + ((cross(_349, _373) * i.world_tangent.w) * m.y)) + (_349 * m.z));\n    float3 _404;\n    if (i.front_facing)\n    {\n        _404 = _401;\n    }\n    else\n    {\n        _404 = -_401;\n    }\n    return _404;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _469_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5108 = fa_tex_fix(param_2, param_3);\n    float4 _6246 = base_t;\n    _6246.x = _5108.x;\n    _6246.y = _5108.y;\n    _6246.z = _5108.z;\n    base_t = _6246;\n    float4 _5122 = (_6246 * _469_fa_base_color) * i.vertex_color;\n    float3 _6052 = i.world_normal;\n    if (_469_fa_maps.z > 0.5f)\n    {\n        float param_4 = _469_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5154 = fa_tex_fix(param_6, param_7);\n        float3 _5157 = (_5154 * 2.0f) - 1.0f.xxx;\n        float2 _5162 = _5157.xy * _469_fa_maps.x;\n        float3 _6254 = _5157;\n        _6254.x = _5162.x;\n        _6254.y = _5162.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6254;\n        _6052 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _469_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5190 = fa_tex_fix(param_12, param_13);\n    float4 _6257 = mrt;\n    _6257.x = _5190.x;\n    _6257.y = _5190.y;\n    _6257.z = _5190.z;\n    mrt = _6257;\n    float4 _5218 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _469_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5229 = fa_tex_fix(param_16, param_17);\n    float param_18 = _469_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5259 = fa_tex_fix(param_20, param_21);\n    float _6057 = _469_fa_layers_a.x;\n    float _6058 = _469_fa_layers_a.y;\n    float _6061 = _469_fa_layers_a.z;\n    float _6060 = _469_fa_layers_b.w;\n    float _6063 = _469_fa_layers_c.x;\n    if (_469_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_469_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6057 *= _5229.y;\n            _6058 *= _5229.z;\n            _6060 *= _5218.w;\n        }\n        if (_469_fa_layers_c.z > 1.5f)\n        {\n            _6061 *= mrt.x;\n            _6063 *= mrt.w;\n        }\n    }\n    Surface _6090 = { _5122.xyz, _5122.w, _6052, clamp(_469_fa_pbr.x * _5190.z, 0.0f, 1.0f), clamp(_469_fa_pbr.y * _5190.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_469_fa_maps.y * (_5229.x - 1.0f)), _469_fa_emissive.xyz + (_469_fa_model_emissive.xyz * _5259), _6057, _6058, _469_fa_layers_b.xyz, _6060, _6061, _469_fa_layers_a.w, _6063, _469_fa_layers_c.y, _469_fa_layers_d.xyz, _469_fa_tr_a.x, _469_fa_tr_a.y, _469_fa_tr_b.xyz, _469_fa_tr_a.z };\n    return _6090;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1629 = rect.zw - rect.xy;\n    float2 _1633 = _1629 * atlas;\n    float2 _1637 = ddx * _1633;\n    float2 _1641 = ddy * _1633;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1629), clamp(0.5f * log2(max(max(dot(_1637, _1637), dot(_1641, _1641)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1674 = _469_fa_counts.y < 0.5f;\n    bool _1681;\n    if (!_1674)\n    {\n        _1681 = _469_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1681 = _1674;\n    }\n    if (_1681)\n    {\n        return;\n    }\n    float3 _1687 = ddx(world_pos);\n    float3 _1690 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1694 = fa_cluster_texel(param);\n    int _1698 = int(_1694.w);\n    if (_1698 < 1)\n    {\n        return;\n    }\n    int _1708 = int(_469_fa_counts.y + 0.5f);\n    int param_1 = _1708;\n    float4 _1712 = fa_light_texel(param_1);\n    float2 _1715 = _1712.yz;\n    int _1719 = int(_1712.w);\n    int param_2 = _1708 + 1;\n    float4 _1724 = fa_light_texel(param_2);\n    float _1725 = _1724.x;\n    int _1731 = int(_469_fa_counts.w + 0.5f) - 1;\n    int _1735 = int(_1694.z);\n    float3 _2000;\n    for (int k = 0; k < _1698; k++)\n    {\n        int _1748 = _1735 + k;\n        int param_3 = _1719 + (_1748 >> 2);\n        int _1765 = (_1708 + 2) + (int(fa_light_texel(param_3)[_1748 & 3]) * 7);\n        int param_4 = _1765 + 6;\n        float4 _1770 = fa_light_texel(param_4);\n        if (((int(_1770.w + 0.5f) >> _1731) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1765;\n        float4 _1785 = fa_light_texel(param_5);\n        int param_6 = _1765 + 1;\n        float4 _1790 = fa_light_texel(param_6);\n        int param_7 = _1765 + 2;\n        float4 _1795 = fa_light_texel(param_7);\n        float3 _1798 = _1785.xyz;\n        float _1803 = dot(_1798, world_pos) + _1785.w;\n        float3 _1805 = _1790.xyz;\n        float _1810 = dot(_1805, world_pos) + _1790.w;\n        float3 _1812 = _1795.xyz;\n        float _1817 = dot(_1812, world_pos) + _1795.w;\n        bool _1822 = abs(_1803) > 0.5f;\n        bool _1830;\n        if (!_1822)\n        {\n            _1830 = abs(_1810) > 0.5f;\n        }\n        else\n        {\n            _1830 = _1822;\n        }\n        bool _1838;\n        if (!_1830)\n        {\n            _1838 = abs(_1817) > 0.5f;\n        }\n        else\n        {\n            _1838 = _1830;\n        }\n        if (_1838)\n        {\n            continue;\n        }\n        float _1853 = clamp(dot(geo_normal, normalize(_1812)) * _1770.z, 0.0f, 1.0f);\n        if (_1853 <= 0.0f)\n        {\n            continue;\n        }\n        float _1873 = (clamp((0.5f - abs(_1817)) * 10.0f, 0.0f, 1.0f) * _1853) * _1770.x;\n        float2 _1881 = float2(_1803 + 0.5f, 0.5f - _1810);\n        float2 _1891 = float2(dot(_1798, _1687), dot(_1805, _1687));\n        float2 _1901 = float2(dot(_1798, _1690), dot(_1805, _1690));\n        int param_8 = _1765 + 5;\n        float4 _1906 = fa_light_texel(param_8);\n        int param_9 = _1765 + 3;\n        float4 _1911 = fa_light_texel(param_9);\n        int param_10 = _1765 + 4;\n        float4 _1916 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1906.xyz;\n        bool _1926 = _1911.z > _1911.x;\n        if (_1926)\n        {\n            float4 param_11 = _1911;\n            float2 param_12 = _1881;\n            float2 param_13 = _1715;\n            float2 param_14 = _1891;\n            float2 param_15 = _1901;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1725 > 0.5f) && (_1725 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1952 = fa_dc_to_linear(param_16);\n                float4 _6140 = tx;\n                _6140.x = _1952.x;\n                _6140.y = _1952.y;\n                _6140.z = _1952.z;\n                tx = _6140;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1873 * tex_a) * _1906.w, 0.0f, 1.0f).xxx);\n        if (_1916.z > _1916.x)\n        {\n            float4 param_17 = _1916;\n            float2 param_18 = _1881;\n            float2 param_19 = _1715;\n            float2 param_20 = _1891;\n            float2 param_21 = _1901;\n            float4 _1996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1725 > 1.5f)\n            {\n                float3 param_22 = _1996.xyz;\n                float3 _2006 = fa_dc_to_srgb(param_22);\n                _2000 = _2006;\n            }\n            else\n            {\n                _2000 = _1996.xyz;\n            }\n            float3 _2015 = (_2000 * 2.0f) - 1.0f.xxx;\n            float2 _2020 = _2015.xy * _1770.y;\n            float3 _2042 = (normalize(_1798) * _2020.x) + (normalize(_1805) * _2020.y);\n            float3 _2045 = normalize(normal);\n            normal = normalize(lerp(_2045, normalize((_2045 * max(_2015.z, 0.0500000007450580596923828125f)) + (_2042 - (_2045 * dot(_2045, _2042)))), clamp(_1873 * (_1926 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6283;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_469_fa_cl_info.x) + int(_469_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_469_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4662;\n    if (fa_lm.z > 0.5f)\n    {\n        _4662 = 0.0f;\n    }\n    else\n    {\n        _4662 = 1.0f - clamp(_469_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4673 = _4662 < 1.0f;\n    bool _4679;\n    if (_4673)\n    {\n        int param = li;\n        _4679 = fa_light_baked(param);\n    }\n    else\n    {\n        _4679 = _4673;\n    }\n    return _4679 ? _4662 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _647 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _660 = (c - (ru * hx)) - p;\n        float3 _666 = ru * (2.0f * hx);\n        float _672 = max(dot(_666, _666), 9.9999999392252902907785028219223e-09f);\n        float _676 = dot(_660, _666);\n        float t = clamp((-_676) / _672, 0.0f, 1.0f);\n        if (_647)\n        {\n            float _691 = dot(r, _666);\n            float _697 = _672 - (_691 * _691);\n            if (abs(_697) > (9.9999997473787516355514526367188e-06f * _672))\n            {\n                t = clamp(((dot(r, _660) * _691) - _676) / _697, 0.0f, 1.0f);\n            }\n        }\n        return (p + _660) + (_666 * t);\n    }\n    float3 q = p;\n    float _729 = dot(r, axis);\n    bool _737;\n    if (_647)\n    {\n        _737 = abs(_729) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _737 = _647;\n    }\n    if (_737)\n    {\n        float _747 = dot(c - p, axis) / _729;\n        if (_747 > 0.0f)\n        {\n            q = p + (r * _747);\n        }\n    }\n    float3 _760 = q - c;\n    float2 xy = float2(dot(_760, ru), dot(_760, uu));\n    if (shape > 0.5f)\n    {\n        float _775 = length(xy);\n        if (_775 > hx)\n        {\n            xy *= (hx / _775);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _528_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _528_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _567 = dot(d, right);\n    float _571 = dot(d, up);\n    float _582;\n    if (((_567 * _567) + (_571 * _571)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _582 = atan2(_571, _567) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _582 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_582 - floor(_582)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _416 = abs(d);\n    float _418 = _416.x;\n    float _420 = _416.y;\n    bool _421 = _418 >= _420;\n    bool _429;\n    if (_421)\n    {\n        _429 = _418 >= _416.z;\n    }\n    else\n    {\n        _429 = _421;\n    }\n    int _430;\n    if (_429)\n    {\n        _430 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _445;\n        if (_420 >= _416.z)\n        {\n            _445 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _445 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _430 = _445;\n    }\n    return _430;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _813 = fa_light_base(param);\n    bool _817 = _469_fa_ambient.w > 4.5f;\n    int param_1 = _813;\n    float4 _821 = fa_light_texel(param_1);\n    int param_2 = _813 + 1;\n    float4 _826 = fa_light_texel(param_2);\n    float _829 = _826.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _841 = _817 && (_829 > 2.5f);\n    fa_light_is_area = _841;\n    bool _843 = _829 < 0.5f;\n    float3 l;\n    if (_843)\n    {\n        l = normalize(_821.xyz);\n        if (_817)\n        {\n            int param_3 = _813 + 6;\n            float4 _857 = fa_light_texel(param_3);\n            if (_857.z > 0.5f)\n            {\n                int param_4 = _813 + 4;\n                float4 _867 = fa_light_texel(param_4);\n                int param_5 = _813 + 5;\n                float4 _872 = fa_light_texel(param_5);\n                float2 param_6 = _857.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _867.xyz) * _867.w, (-dot(world_pos, _872.xyz)) * _872.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _902 = _821.xyz;\n        float3 _904 = _902 - world_pos;\n        float3 to_light = _904;\n        float _907 = length(_904);\n        float reach = _907;\n        bool front = true;\n        if (_841)\n        {\n            int param_8 = _813 + 7;\n            reach = max(_907 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _813 + 4;\n            float4 _931 = fa_light_texel(param_9);\n            int param_10 = _813 + 5;\n            float4 _936 = fa_light_texel(param_10);\n            int param_11 = _813 + 6;\n            float4 _941 = fa_light_texel(param_11);\n            float _942 = _941.w;\n            int param_12 = _813 + 2;\n            float3 _949 = normalize(fa_light_texel(param_12).xyz);\n            bool _951 = _942 > 1.5f;\n            bool _959;\n            if (!_951)\n            {\n                _959 = dot(_949, to_light) < 0.0f;\n            }\n            else\n            {\n                _959 = _951;\n            }\n            front = _959;\n            float3 r = 0.0f.xxx;\n            float3 _968 = _469_fa_camera_pos.xyz - world_pos;\n            bool _972 = dot(n, n) > 0.5f;\n            bool _980;\n            if (_972)\n            {\n                _980 = dot(_968, _968) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _980 = _972;\n            }\n            if (_980)\n            {\n                r = reflect(-normalize(_968), normalize(n));\n            }\n            float3 param_13 = _902;\n            float3 param_14 = _949;\n            float3 param_15 = _931.xyz;\n            float3 param_16 = _936.xyz;\n            float param_17 = _931.w;\n            float param_18 = _936.w;\n            float param_19 = _942;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1016 = length(to_light);\n        dist = _1016;\n        l = to_light / max(_1016, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1030 = reach / max(_821.w, 0.001000000047497451305389404296875f);\n        float _1036 = clamp(1.0f - (_1030 * _1030), 0.0f, 1.0f);\n        float _1038;\n        if (front)\n        {\n            _1038 = _1036 * _1036;\n        }\n        else\n        {\n            _1038 = 0.0f;\n        }\n        atten = _1038;\n        bool _1049 = _829 < 2.5f;\n        if ((_829 > 1.5f) && _1049)\n        {\n            int param_22 = _813 + 2;\n            float4 _1057 = fa_light_texel(param_22);\n            float _1067 = _1057.w;\n            int param_23 = _813 + 3;\n            float4 _1072 = fa_light_texel(param_23);\n            float _1073 = _1072.x;\n            float cos_inner = _1073;\n            if (_1073 > 1.5f)\n            {\n                cos_inner = lerp(_1067, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1067, cos_inner, dot(-l, normalize(_1057.xyz)));\n        }\n        if (_817 && (_829 < 1.5f))\n        {\n            int param_24 = _813 + 6;\n            float4 _1097 = fa_light_texel(param_24);\n            if (_1097.z > 0.5f)\n            {\n                float3 _1105 = -to_light;\n                int param_25 = _813 + 4;\n                int param_26 = _813 + 5;\n                float3 _1119 = fa_light_texel(param_25).xyz;\n                float3 _1123 = fa_light_texel(param_26).xyz;\n                float3 _1132 = float3(dot(_1105, _1119), dot(_1105, _1123), dot(_1105, cross(_1119, _1123)));\n                float3 param_27 = _1132;\n                int _1136 = fa_cube_face(param_27);\n                int param_28 = _1136;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1163 = float2(dot(_1132, cross(param_29, param_30)), dot(_1132, param_30)) / max(dot(_1132, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1167 = _1136 / 3;\n                float2 param_31 = _1097.xy + (float2(float(_1136 - (_1167 * 3)), float(_1167)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1163.x), 0.5f - (0.5f * _1163.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _813 + 7;\n            float4 _1197 = fa_light_texel(param_33);\n            if (_1197.z > 0.5f)\n            {\n                int param_34 = _813 + 2;\n                int param_35 = _813 + 4;\n                int param_36 = _813 + 5;\n                float2 param_37 = _1197.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_817 && _1049)\n            {\n                int param_42 = _813 + 6;\n                float4 _1244 = fa_light_texel(param_42);\n                int param_43 = _813 + 7;\n                float4 _1249 = fa_light_texel(param_43);\n                bool _1252 = _1244.z > 0.5f;\n                bool _1259;\n                if (!_1252)\n                {\n                    _1259 = _1249.z > 0.5f;\n                }\n                else\n                {\n                    _1259 = _1252;\n                }\n                if (_1259)\n                {\n                    int param_44 = _813 + 2;\n                    float4 _1266 = fa_light_texel(param_44);\n                    float3 _1270 = normalize(_1266.xyz);\n                    int param_45 = _813 + 4;\n                    float4 _1275 = fa_light_texel(param_45);\n                    int param_46 = _813 + 5;\n                    float4 _1280 = fa_light_texel(param_46);\n                    if (_1252)\n                    {\n                        float3 _1288 = -to_light;\n                        float _1295 = _1266.w;\n                        float _1311 = 0.5f / max(dot(_1288, _1270) * (sqrt(max(1.0f - (_1295 * _1295), 0.0f)) / max(_1295, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1244.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1288, _1275.xyz) * _1311), 0.5f - (dot(_1288, _1280.xyz) * _1311));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1249.z > 0.5f)\n                    {\n                        float2 param_49 = _1249.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1270;\n                        float3 param_52 = _1275.xyz;\n                        float3 param_53 = _1280.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5858 = _826.xyz * atten;\n    if (_817)\n    {\n        _5858 *= fa_light_tint;\n    }\n    int _1380;\n    if (_843)\n    {\n        _1380 = 0;\n    }\n    else\n    {\n        _1380 = ((_829 > 1.5f) && (_829 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5869 = { l, _5858, atten, 1.0f, dist, _1380 };\n    return _5869;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4891 = n < 0;\n    bool _4898;\n    if (!_4891)\n    {\n        _4898 = n >= fa_light_count();\n    }\n    else\n    {\n        _4898 = _4891;\n    }\n    if (_4898)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4906 = fa_cl_light(param);\n    int param_1 = _4906;\n    float _4910 = fa_baked_keep(param_1);\n    if (_4910 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4906;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4926 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6040 = { _4926.direction, _4926.color * _4910, _4926.attenuation * _4910, _4926.shadow, _4926._distance, _4926.type };\n    return _6040;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2174 = fa_shadow_depth(param, param_1);\n    float _2178;\n    if (conv.x < 0.5f)\n    {\n        _2178 = _2174;\n    }\n    else\n    {\n        _2178 = (conv.y * conv.z) / (conv.z - (_2174 * (conv.z - conv.y)));\n    }\n    return _2178;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2105 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2105), sin(_2105)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2224 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2253 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2224;\n            float2 _2272 = fa_shadow_vogel(param_3, param_4, param_5) * _2253;\n            float2 param_6 = uv + (_2272 * _2127_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2284 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2284 < (zr - (length(_2272) * plane)))\n            {\n                sum += _2284;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2310 = sum / cnt;\n        float _2320;\n        if (k < 0.0f)\n        {\n            _2320 = (-k) / max(_2310, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2320 = k;\n        }\n        radius = clamp(((max(zr - _2310, 0.0f) * unit) * _2320) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2342 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2342; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2342;\n        float param_11 = _2224;\n        float2 _2361 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2361 * _2127_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2361) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2342);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2561 = _469_fa_pbr.z < 0.5f;\n    bool _2568;\n    if (!_2561)\n    {\n        _2568 = _2127_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2568 = _2561;\n    }\n    if (_2568)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2127_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2581 = fa_light_texel(param);\n    float _2582 = _2581.x;\n    if (_2582 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2591 = int(_2582 + 0.5f);\n    int param_1 = _2591;\n    float4 _2595 = fa_light_texel(param_1);\n    int param_2 = _2591 + 1;\n    float4 _2600 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2603 = _2595.y;\n    if (_2603 > 0.0f)\n    {\n        float _2620 = 1.0f - smoothstep(0.75f * _2603, _2603, length(world - _2127_fa_shadow_eye.xyz));\n        fade = _2620;\n        if (_2620 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2595.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2644 = (_2591 + 2) + (face * 6);\n    int param_4 = _2644;\n    int param_5 = _2644 + 1;\n    int param_6 = _2644 + 3;\n    float4 _2658 = fa_light_texel(param_6);\n    int param_7 = _2644 + 4;\n    float4 _2663 = fa_light_texel(param_7);\n    int param_8 = _2644 + 5;\n    float4 _2668 = fa_light_texel(param_8);\n    float _2680 = _2668.x * max(dot(_2658, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2685 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2708 = clamp(dot(n, _2658.xyz), -1.0f, 1.0f);\n    float _2727 = min(sqrt(1.0f - (_2708 * _2708)) / max(abs(dot(n, world - lpos)) / max(dot(_2658, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2730 = _2600.y;\n    float _2732;\n    if (_2730 > 0.0f)\n    {\n        _2732 = _2730;\n    }\n    else\n    {\n        _2732 = 1.5f * _2680;\n    }\n    float4 _2752 = float4(world + (n * (_2732 * sqrt(1.0f - (_2685 * _2685)))), 1.0f);\n    float _2756 = dot(_2658, _2752);\n    float _2759 = _2668.y;\n    if (_2756 < _2759)\n    {\n        return 1.0f;\n    }\n    float2 _2774 = float2(dot(fa_light_texel(param_4), _2752), dot(fa_light_texel(param_5), _2752)) / _2756.xx;\n    float _2776 = _2774.x;\n    bool _2779 = _2776 < _2663.x;\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2776 > _2663.z;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2774.y < _2663.y;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    bool _2806;\n    if (!_2797)\n    {\n        _2806 = _2774.y > _2663.w;\n    }\n    else\n    {\n        _2806 = _2797;\n    }\n    if (_2806)\n    {\n        return 1.0f;\n    }\n    float _2812 = _2600.x;\n    float _2814;\n    if (_2812 > 0.0f)\n    {\n        _2814 = _2812;\n    }\n    else\n    {\n        _2814 = 1.5f * _2680;\n    }\n    float2 param_9 = _2774;\n    float4 param_10 = _2663;\n    float param_11 = _2756 - (_2814 * (1.0f + (0.5f * _2727)));\n    float param_12 = _2680;\n    float param_13 = 1.0f;\n    float param_14 = _2668.z * 0.25f;\n    float param_15 = (_2680 * min(_2727, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2759, _2668.z);\n    int param_17 = int(_2595.z + 0.5f);\n    float param_18 = _2595.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2117;\n    if (i == 0)\n    {\n        _2117 = _2127_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2133;\n        if (i == 1)\n        {\n            _2133 = _2127_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2141;\n            if (i == 2)\n            {\n                _2141 = _2127_fa_shadow_split.z;\n            }\n            else\n            {\n                _2141 = _2127_fa_shadow_split.w;\n            }\n            _2133 = _2141;\n        }\n        _2117 = _2133;\n    }\n    return _2117;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2403 = max(_2127_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2408 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2414 = sqrt(1.0f - (_2408 * _2408));\n    float _2421 = min(_2414 / max(_2408, 0.20000000298023223876953125f), 4.0f);\n    float _2426;\n    if (_2127_fa_shadow_bias.y > 0.0f)\n    {\n        _2426 = _2127_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2426 = 1.5f * _2127_fa_shadow_info[ci].x;\n    }\n    float4 _2451 = mul(float4(world + (n * (_2426 * _2414)), 1.0f), _2127_fa_shadow_mat[ci]);\n    float _2458 = _2451.x;\n    bool _2461 = _2458 < _2127_fa_shadow_rect[ci].x;\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2458 > _2127_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2451.y < _2127_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2488;\n    if (!_2479)\n    {\n        _2488 = _2451.y > _2127_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2488 = _2479;\n    }\n    bool _2495;\n    if (!_2488)\n    {\n        _2495 = _2451.z > 1.0f;\n    }\n    else\n    {\n        _2495 = _2488;\n    }\n    if (_2495)\n    {\n        return -1.0f;\n    }\n    float _2503;\n    if (_2127_fa_shadow_bias.x > 0.0f)\n    {\n        _2503 = _2127_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2503 = 1.5f * _2127_fa_shadow_info[ci].x;\n    }\n    float2 param = _2451.xy;\n    float4 param_1 = _2127_fa_shadow_rect[ci];\n    float param_2 = _2451.z - ((_2503 * (1.0f + (0.5f * _2421))) / _2403);\n    float param_3 = _2127_fa_shadow_info[ci].x;\n    float param_4 = _2403;\n    float param_5 = _2403 * 0.25f;\n    float param_6 = ((_2127_fa_shadow_info[ci].x * min(_2421, 3.0f)) * 0.5f) / _2403;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2127_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2127_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_469_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2881 = int(_2127_fa_shadow_cfg.x + 0.5f);\n    if (_2881 < 1)\n    {\n        return 1.0f;\n    }\n    float _2896 = dot(world - _2127_fa_shadow_eye.xyz, _2127_fa_shadow_fwd.xyz);\n    int param = _2881 - 1;\n    if (_2896 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2908 = _2881 > 1;\n    bool _2915;\n    if (_2908)\n    {\n        _2915 = _2896 > _2127_fa_shadow_split.x;\n    }\n    else\n    {\n        _2915 = _2908;\n    }\n    if (_2915)\n    {\n        ci = 1;\n    }\n    bool _2919 = _2881 > 2;\n    bool _2926;\n    if (_2919)\n    {\n        _2926 = _2896 > _2127_fa_shadow_split.y;\n    }\n    else\n    {\n        _2926 = _2919;\n    }\n    if (_2926)\n    {\n        ci = 2;\n    }\n    bool _2930 = _2881 > 3;\n    bool _2937;\n    if (_2930)\n    {\n        _2937 = _2896 > _2127_fa_shadow_split.z;\n    }\n    else\n    {\n        _2937 = _2930;\n    }\n    if (_2937)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2881)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2963 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2963;\n        if (_2963 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2127_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2988;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2988 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2988 = _2127_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3007 = _2127_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2988, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3018 = clamp((_2896 - (fa_shadow_split_at(param_7) - _3007)) / _3007, 0.0f, 1.0f);\n        if (_3018 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2881)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3039 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3039;\n                if (_3039 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3018);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4406 = _469_fa_ct_a.x < 0.5f;\n    bool _4413;\n    if (!_4406)\n    {\n        _4413 = _2127_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4413 = _4406;\n    }\n    if (_4413)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2127_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4426 = fa_light_texel(param);\n    float _4427 = _4426.y;\n    float len = _4427;\n    if (_4427 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4439 = length(world - _469_fa_camera_pos.xyz);\n    float _4449 = 1.0f - smoothstep(0.5f * _469_fa_ct_b.x, _469_fa_ct_b.x, _4439);\n    if (_4449 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4455 = len;\n    float _4458 = min(_4455, 0.89999997615814208984375f * dist);\n    len = _4458;\n    float _4463 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4439);\n    float _4468 = _4463 + (0.5f * _4458);\n    float3 _4474 = world + (gn * _4463);\n    float _4476 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4540;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4491 = (float(k) + _4476) * 0.083333335816860198974609375f;\n        float3 _4499 = _4474 + (l * (_4491 * len));\n        float4 _4505 = float4(_4499, 1.0f);\n        float _4511 = dot(_469_fa_ct_vpw, _4505);\n        if (_4511 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4531 = float2(dot(_469_fa_ct_vpx, _4505), dot(_469_fa_ct_vpy, _4505)) / _4511.xx;\n        float _4535 = _4531.x * 0.5f;\n        float _4536 = _4535 + 0.5f;\n        if (_469_fa_ct_a.y > 0.5f)\n        {\n            _4540 = (_4531.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4540 = 0.5f - (_4531.y * 0.5f);\n        }\n        bool _4556 = _4536 < 0.0f;\n        bool _4563;\n        if (!_4556)\n        {\n            _4563 = _4536 >= 1.0f;\n        }\n        else\n        {\n            _4563 = _4556;\n        }\n        bool _4570;\n        if (!_4563)\n        {\n            _4570 = _4540 < 0.0f;\n        }\n        else\n        {\n            _4570 = _4563;\n        }\n        bool _4577;\n        if (!_4570)\n        {\n            _4577 = _4540 >= 1.0f;\n        }\n        else\n        {\n            _4577 = _4570;\n        }\n        if (_4577)\n        {\n            break;\n        }\n        float4 _4596 = fa_screen_tex.Load(int3(int2(float2(_4536, _4540) * _469_fa_ct_a.zw), 0));\n        if (_4596.w < 0.5f)\n        {\n            continue;\n        }\n        float _4615 = (dot(_469_fa_ct_fwd.xyz, _4499) + _469_fa_ct_fwd.w) - _4596.x;\n        if ((_4615 > _4463) && (_4615 < _4468))\n        {\n            occ = max(occ, (1.0f - (_4491 * _4491)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4536, 0.5f - _4535), min(_4540, 1.0f - _4540))));\n        }\n    }\n    return 1.0f - (occ * _4449);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4718 = fa_baked_keep(param);\n    if (_4718 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6002 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6002;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4744 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6004 = _4744.color;\n    float _6005 = _4744.attenuation;\n    float _6006 = _4744.shadow;\n    bool _4747 = _4744.type == 0;\n    if (_4747 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4744.direction;\n        float _4758 = fa_shadow_factor(param_5, param_6);\n        _6006 = _4758;\n        _6004 *= _4758;\n    }\n    else\n    {\n        bool _4769 = _4744.type != 0;\n        bool _4775;\n        if (_4769)\n        {\n            _4775 = _6005 > 0.0f;\n        }\n        else\n        {\n            _4775 = _4769;\n        }\n        if (_4775)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4744.direction;\n            float _4794 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6006 = _4794;\n            _6004 *= _4794;\n        }\n    }\n    bool _4804 = _469_fa_ct_a.x > 0.5f;\n    bool _4810;\n    if (_4804)\n    {\n        _4810 = _6005 > 0.0f;\n    }\n    else\n    {\n        _4810 = _4804;\n    }\n    if (_4810)\n    {\n        float _4817;\n        if (_4747)\n        {\n            _4817 = 1000000000.0f;\n        }\n        else\n        {\n            _4817 = _4744._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4744.direction;\n        float param_18 = _4817;\n        float _4835 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6006 *= _4835;\n        _6004 *= _4835;\n    }\n    float _4848 = _6005;\n    float _4849 = _4848 * _4718;\n    _6005 = _4849;\n    float3 _4853 = _6004;\n    float3 _4854 = _4853 * _4718;\n    _6004 = _4854;\n    LightSample _6021 = { _4744.direction, _4854, _4849, _6006, _4744._distance, _4744.type };\n    return _6021;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4865 = n < 0;\n    bool _4872;\n    if (!_4865)\n    {\n        _4872 = n >= fa_light_count();\n    }\n    else\n    {\n        _4872 = _4865;\n    }\n    if (_4872)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4887 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4887;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3797 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3805 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3808 = int(_3797);\n    int _3811 = int(_3805);\n    float _3821 = _3805 - float(_3811);\n    int _3877 = (_3808 * 9) + _3811;\n    int _3897 = ((_3808 + 1) * 9) + _3811;\n    return lerp(lerp(_3872[_3877], _3872[_3877 + 1], _3821), lerp(_3872[_3897], _3872[_3897 + 1], _3821), _3797 - float(_3808));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5870 = false;\n    float _5871 = 1.0f;\n    float _5872 = 1.0f;\n    float _5873 = 1.0f;\n    float _5874 = 0.0f;\n    float _5875 = 0.0f;\n    float _5876 = 0.0f;\n    float _5877 = 0.0f;\n    float _5879 = 1.0f;\n    bool _5880 = false;\n    float3 _5881 = 0.0f.xxx;\n    float _5882 = 1.0f;\n    float _5883 = 1.0f;\n    float _5884 = 1.0f;\n    float _5885 = 0.0f;\n    float _5886 = 0.0f;\n    float3 _5887 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5888 = float3(0.0f, 0.0f, 1.0f);\n    float _5889 = 1.0f;\n    float _5890 = 1.0f;\n    float _3948 = clamp(s.specular, 0.0f, 1.0f);\n    float _3952 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3957 = (_3948 != 1.0f) || (_3952 != 1.5f);\n    bool _3966;\n    if (!_3957)\n    {\n        _3966 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3966 = _3957;\n    }\n    if (_3966)\n    {\n        float _3974 = (_3952 - 1.0f) / (_3952 + 1.0f);\n        f0 = lerp(min((_3974 * _3974).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3948, s.albedo, metallic.xxx);\n        _5871 = lerp(_3948, 1.0f, metallic);\n        _5870 = true;\n    }\n    float _4001 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4001 > 0.0f)\n    {\n        float _4009 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5874 = _4001;\n        _5875 = _4009;\n        float _4016 = _4009 * _4009;\n        _5876 = _4016;\n        _5877 = _4016 * _4016;\n        float _4028 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5879 = _4028;\n        _5872 = 1.0f - (_4001 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4028, 0.0f, 1.0f), 5.0f))));\n        _5870 = true;\n    }\n    float3 _4047 = max(s.sheen_color, 0.0f.xxx);\n    float _4056 = max(_4047.x, max(_4047.y, _4047.z));\n    if (_4056 > 0.0f)\n    {\n        float _4064 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5880 = true;\n        _5881 = _4047;\n        _5882 = _4064;\n        _5883 = _4064 * _4064;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4064;\n        float _4081 = fa_sheen_albedo(param, param_1);\n        _5885 = _4081;\n        _5884 = 1.0f - min(_4056 * _4081, 1.0f);\n        _5870 = true;\n    }\n    _5873 = _5872 * _5884;\n    float _4100 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4100 != 0.0f)\n    {\n        float3 _4115 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4115;\n        if (dot(_4115, _4115) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4127 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4127.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4127.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4127.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4131 = t;\n        float3 _4132 = normalize(_4131);\n        t = _4132;\n        float3 _4157 = normalize((_4132 * cos(s.anisotropy_rotation)) + ((cross(n, _4132) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5887 = _4157;\n        _5888 = cross(n, _4157);\n        float _4167 = roughness * roughness;\n        float _4173 = lerp(_4167, 1.0f, _4100 * _4100);\n        bool _4175 = _4100 > 0.0f;\n        _5889 = _4175 ? _4173 : _4167;\n        _5890 = _4175 ? _4167 : _4173;\n        _5886 = _4100;\n        _5870 = true;\n    }\n    FaLayers _5912 = { _5870, _5871, _5872, _5873, _5874, _5875, _5876, _5877, i.world_normal, _5879, _5880, _5881, _5882, _5883, _5884, _5885, _5886, _5887, _5888, _5889, _5890 };\n    return _5912;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3729 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3732 = _3729.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3732 * _3732, exp2((-9.27999973297119140625f) * ndv)) * _3732) + _3729.y)) + _3729.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3165 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3168 = _3165.x;\n    float _3170 = _3165.z;\n    float2 e = float2(_3168, _3170);\n    if (_3165.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3170)) * ((_3168 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3168)) * ((_3170 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3204_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3204_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3217;\n    if (lv == 0)\n    {\n        _3217 = 0.0f;\n    }\n    else\n    {\n        _3217 = res + 2.0f;\n    }\n    float _3227;\n    if (lv == 0)\n    {\n        _3227 = 0.0f;\n    }\n    else\n    {\n        _3227 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3217, _3227)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3272;\n    if (res > 64.5f)\n    {\n        _3272 = 5.0f;\n    }\n    else\n    {\n        _3272 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3287 = clamp(rough, 0.0f, 1.0f) * (_3272 - 1.0f);\n    int _3294 = int(min(floor(_3287), _3272 - 2.0f));\n    float _3299 = _3287 - float(_3294);\n    float3 param = d;\n    float2 _3303 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3294;\n    float2 param_4 = _3303;\n    float3 _3313 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3299 < 0.00200000009499490261077880859375f)\n    {\n        return _3313;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3294 + 1;\n    float2 param_8 = _3303;\n    return lerp(_3313, fa_probe_level(param_5, param_6, param_7, param_8), _3299.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3351 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3358 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3365 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3371 = dot(bx.xyz, d);\n    float _3375 = dot(by.xyz, d);\n    float _3379 = dot(bz.xyz, d);\n    float _3385;\n    if (_3371 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3385 = (1.0f - _3351) / _3371;\n    }\n    else\n    {\n        float _3399;\n        if (_3371 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3399 = ((-1.0f) - _3351) / _3371;\n        }\n        else\n        {\n            _3399 = 1000000015047466219876688855040.0f;\n        }\n        _3385 = _3399;\n    }\n    float tx = _3385;\n    float _3416;\n    if (_3375 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3416 = (1.0f - _3358) / _3375;\n    }\n    else\n    {\n        float _3429;\n        if (_3375 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3429 = ((-1.0f) - _3358) / _3375;\n        }\n        else\n        {\n            _3429 = 1000000015047466219876688855040.0f;\n        }\n        _3416 = _3429;\n    }\n    float ty = _3416;\n    float _3445;\n    if (_3379 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3445 = (1.0f - _3365) / _3379;\n    }\n    else\n    {\n        float _3458;\n        if (_3379 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3458 = ((-1.0f) - _3365) / _3379;\n        }\n        else\n        {\n            _3458 = 1000000015047466219876688855040.0f;\n        }\n        _3445 = _3458;\n    }\n    float _3470 = tx;\n    float _3473 = (_3470 > 0.0f) ? _3470 : 1000000015047466219876688855040.0f;\n    tx = _3473;\n    float _3474 = ty;\n    float _3477 = (_3474 > 0.0f) ? _3474 : 1000000015047466219876688855040.0f;\n    ty = _3477;\n    float _3487 = min(_3473, min(_3477, (_3445 > 0.0f) ? _3445 : 1000000015047466219876688855040.0f));\n    if (_3487 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3503 = (fa_world_pos + (d * _3487)) - posw.xyz;\n    float3 _3508;\n    if (dot(_3503, _3503) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3508 = normalize(_3503);\n    }\n    else\n    {\n        _3508 = d;\n    }\n    return _3508;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3554 = (1.0f - _469_fa_rpa_tile.w) - _469_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3554 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_469_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _469_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3584 = rough * rough;\n            float _3615 = 0.60000002384185791015625f * _3584;\n            base = lerp(lerp(_469_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_469_fa_env_horizon.xyz, _469_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3584)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3615, 0.0500000007450580596923828125f + _3615, d.y).xxx), ((_469_fa_env_sky.xyz + _469_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3584 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3554;\n    }\n    if (_469_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _469_fa_rpa_tile;\n        float4 param_5 = _469_fa_rpa_pos;\n        float4 param_6 = _469_fa_rpa_bx;\n        float4 param_7 = _469_fa_rpa_by;\n        float4 param_8 = _469_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3674 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3674 * _469_fa_rpa_tile.w);\n    }\n    if (_469_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _469_fa_rpb_tile;\n        float4 param_12 = _469_fa_rpb_pos;\n        float4 param_13 = _469_fa_rpb_bx;\n        float4 param_14 = _469_fa_rpb_by;\n        float4 param_15 = _469_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3706 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3706 * _469_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4208;\n        if (L.aniso >= 0.0f)\n        {\n            _4208 = L.b;\n        }\n        else\n        {\n            _4208 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4208, v), _4208), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4241 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4241.x) + (L.f90.xxx * _4241.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4296 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4296.x) + _4296.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3771 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3771.x) + _3771.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4335 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4339 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4346 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4335.xxx);\n    float3 f0 = _4346;\n    float3 _4350 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4350;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4335;\n    float param_5 = _4339;\n    float3 param_6 = _4346;\n    FaLayers _4367 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4367.on)\n    {\n        FaLayers param_7 = _4367;\n        float3 param_8 = _4350;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4339;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _4350;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _4339;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4957 = fa_light_unshadowed(param, param_1);\n        float _4965 = dot(_4957.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4965 > bestPower)\n        {\n            bestPower = _4965;\n            best = n;\n        }\n    }\n    float3 lit = (_469_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4994 = fa_light(param_2, param_3);\n        float _5002;\n        if (dot(s.normal, _4994.direction) > 0.5f)\n        {\n            _5002 = 1.0f;\n        }\n        else\n        {\n            _5002 = _5008_dark;\n        }\n        lit += ((s.albedo * _4994.color) * _5002);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5008_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2127_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3063 = int(_2127_fa_shadow_cfg.x + 0.5f);\n    float _3073 = dot(world - _2127_fa_shadow_eye.xyz, _2127_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3078 = _3063 > 0;\n    bool _3087;\n    if (_3078)\n    {\n        int param = _3063 - 1;\n        _3087 = _3073 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3087 = _3078;\n    }\n    if (_3087)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3093 = _3063 > 1;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3073 > _2127_fa_shadow_split.x;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3106 = _3063 > 2;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3073 > _2127_fa_shadow_split.y;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3119 = _3063 > 3;\n        bool _3126;\n        if (_3119)\n        {\n            _3126 = _3073 > _2127_fa_shadow_split.z;\n        }\n        else\n        {\n            _3126 = _3119;\n        }\n        if (_3126)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5724 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5724 = -_5724;\n    }\n    float3 _5395 = normalize(_469_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5737 = { fa_world_pos, _5724, fa_world_tangent, fa_uv, fa_vertex_color, _5395, gl_FrontFacing };\n    SurfaceInput param_1 = _5737;\n    Surface _5403 = fa_standard_surface(param_1);\n    float3 _5755 = _5403.albedo;\n    float _5756 = _5403.alpha;\n    float3 _5757 = _5403.normal;\n    float _5758 = _5403.metallic;\n    float _5759 = _5403.roughness;\n    float _5760 = _5403.occlusion;\n    float3 _5761 = _5403.emission;\n    float _5762 = _5403.clearcoat;\n    float _5763 = _5403.clearcoat_roughness;\n    float3 _5764 = _5403.sheen_color;\n    float _5765 = _5403.sheen_roughness;\n    float _5766 = _5403.anisotropy;\n    float _5767 = _5403.anisotropy_rotation;\n    float _5768 = _5403.specular;\n    float _5769 = _5403.ior;\n    float3 _5770 = _5403.specular_color;\n    float _5771 = _5403.transmission;\n    float _5772 = _5403.thickness;\n    float3 _5773 = _5403.attenuation_color;\n    float _5774 = _5403.attenuation_distance;\n    SurfaceInput _5745 = { fa_world_pos, _5724, fa_world_tangent, fa_uv, fa_vertex_color, _5395, gl_FrontFacing };\n    SurfaceInput param_2 = _5745;\n    Surface param_3 = _5403;\n    surface(param_2, param_3);\n    _5755 = param_3.albedo;\n    _5756 = param_3.alpha;\n    _5757 = param_3.normal;\n    _5758 = param_3.metallic;\n    _5759 = param_3.roughness;\n    _5760 = param_3.occlusion;\n    _5761 = param_3.emission;\n    _5762 = param_3.clearcoat;\n    _5763 = param_3.clearcoat_roughness;\n    _5764 = param_3.sheen_color;\n    _5765 = param_3.sheen_roughness;\n    _5766 = param_3.anisotropy;\n    _5767 = param_3.anisotropy_rotation;\n    _5768 = param_3.specular;\n    _5769 = param_3.ior;\n    _5770 = param_3.specular_color;\n    _5771 = param_3.transmission;\n    _5772 = param_3.thickness;\n    _5773 = param_3.attenuation_color;\n    _5774 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5724;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5755 = param_6;\n    _5757 = param_7;\n    float3 result;\n    if (_469_fa_emissive.w > 0.5f)\n    {\n        result = _5755;\n    }\n    else\n    {\n        float3 _5442 = _5757;\n        float3 _5443 = normalize(_5442);\n        _5757 = _5443;\n        SurfaceInput _5753 = { fa_world_pos, _5724, fa_world_tangent, fa_uv, fa_vertex_color, _5395, gl_FrontFacing };\n        SurfaceInput param_8 = _5753;\n        Surface _5856 = { _5755, _5756, _5443, _5758, _5759, _5760, _5761, _5762, _5763, _5764, _5765, _5766, _5767, _5768, _5769, _5770, _5771, _5772, _5773, _5774 };\n        Surface param_9 = _5856;\n        float3 _5454 = lighting(param_8, param_9);\n        result = _5454;\n    }\n    float3 _5458 = result;\n    float3 _5459 = _5458 + _5761;\n    result = _5459;\n    float3 param_10 = _5459;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5468 = _469_fa_fog.w > 0.0f;\n    bool _5475;\n    if (!_5468)\n    {\n        _5475 = _469_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5475 = _5468;\n    }\n    if (_5475)\n    {\n        float3 _5484 = fa_world_pos - _469_fa_camera_pos.xyz;\n        float _5490 = dot(_5484, _469_fa_fog_c.xyz);\n        bool _5494 = _469_fa_fog_c.w > 0.5f;\n        float _5495;\n        if (_5494)\n        {\n            _5495 = _5490;\n        }\n        else\n        {\n            _5495 = length(_5484);\n        }\n        float _5507 = _5495 - _469_fa_fog_b.x;\n        if (_5507 > 0.0f)\n        {\n            float _5516 = _469_fa_fog.w * _5507;\n            float tau = _5516 * _5516;\n            if (_469_fa_fog_b.y > 0.0f)\n            {\n                float _5532;\n                if (_5494)\n                {\n                    _5532 = fa_world_pos.y - (_469_fa_fog_c.y * _5490);\n                }\n                else\n                {\n                    _5532 = _469_fa_camera_pos.y;\n                }\n                float _5553 = lerp(_5532, fa_world_pos.y, clamp(_469_fa_fog_b.x / _5495, 0.0f, 1.0f));\n                float _5557 = fa_world_pos.y - _5553;\n                float _5562 = _5553 - _469_fa_fog_b.z;\n                float _5567 = fa_world_pos.y - _469_fa_fog_b.z;\n                bool _5570 = _5562 <= 0.0f;\n                bool _5571 = !_5570;\n                bool _5577;\n                if (_5571)\n                {\n                    _5577 = _469_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5577 = _5570;\n                }\n                float _5578;\n                if (_5577)\n                {\n                    _5578 = _469_fa_fog_b.y;\n                }\n                else\n                {\n                    _5578 = _469_fa_fog_b.y * exp(-min(_469_fa_fog_b.w * _5562, 80.0f));\n                }\n                bool _5605;\n                if (_5571)\n                {\n                    _5605 = _469_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5605 = _5570;\n                }\n                float _5606;\n                if (_5605)\n                {\n                    _5606 = _469_fa_fog_b.y * _5562;\n                }\n                else\n                {\n                    _5606 = (_469_fa_fog_b.y * (1.0f - exp(-min(_469_fa_fog_b.w * _5562, 80.0f)))) / _469_fa_fog_b.w;\n                }\n                bool _5631 = _5567 <= 0.0f;\n                bool _5638;\n                if (!_5631)\n                {\n                    _5638 = _469_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5638 = _5631;\n                }\n                float _5639;\n                if (_5638)\n                {\n                    _5639 = _469_fa_fog_b.y * _5567;\n                }\n                else\n                {\n                    _5639 = (_469_fa_fog_b.y * (1.0f - exp(-min(_469_fa_fog_b.w * _5567, 80.0f)))) / _469_fa_fog_b.w;\n                }\n                float _5666;\n                if (abs(_5557) < 0.001000000047497451305389404296875f)\n                {\n                    _5666 = _5578;\n                }\n                else\n                {\n                    _5666 = (_5639 - _5606) / _5557;\n                }\n                tau += (_5507 * max(_5666, 0.0f));\n            }\n            result = lerp(result, _469_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5756);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_469",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2127",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5008",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3872[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6283 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _469_fa_camera_pos : packoffset(c0);\n    float4 _469_fa_ambient : packoffset(c1);\n    float4 _469_fa_base_color : packoffset(c2);\n    float4 _469_fa_emissive : packoffset(c3);\n    float4 _469_fa_model_emissive : packoffset(c4);\n    float4 _469_fa_pbr : packoffset(c5);\n    float4 _469_fa_maps : packoffset(c6);\n    float4 _469_fa_fog : packoffset(c7);\n    float4 _469_fa_fog_b : packoffset(c8);\n    float4 _469_fa_fog_c : packoffset(c9);\n    float4 _469_fa_counts : packoffset(c10);\n    float4 _469_fa_env_sky : packoffset(c11);\n    float4 _469_fa_env_horizon : packoffset(c12);\n    float4 _469_fa_time : packoffset(c13);\n    float4 _469_fa_cl_vpx : packoffset(c14);\n    float4 _469_fa_cl_vpy : packoffset(c15);\n    float4 _469_fa_cl_vpw : packoffset(c16);\n    float4 _469_fa_cl_fwd : packoffset(c17);\n    float4 _469_fa_cl_grid : packoffset(c18);\n    float4 _469_fa_cl_info : packoffset(c19);\n    float4 _469_fa_layers_a : packoffset(c20);\n    float4 _469_fa_layers_b : packoffset(c21);\n    float4 _469_fa_layers_c : packoffset(c22);\n    float4 _469_fa_layers_d : packoffset(c23);\n    float4 _469_fa_ct_a : packoffset(c24);\n    float4 _469_fa_ct_b : packoffset(c25);\n    float4 _469_fa_ct_vpx : packoffset(c26);\n    float4 _469_fa_ct_vpy : packoffset(c27);\n    float4 _469_fa_ct_vpw : packoffset(c28);\n    float4 _469_fa_ct_fwd : packoffset(c29);\n    float4 _469_fa_tr_a : packoffset(c30);\n    float4 _469_fa_tr_b : packoffset(c31);\n    float4 _469_fa_probe_sh[9] : packoffset(c32);\n    float4 _469_fa_atlas : packoffset(c41);\n    float4 _469_fa_rpa_tile : packoffset(c42);\n    float4 _469_fa_rpa_pos : packoffset(c43);\n    float4 _469_fa_rpa_bx : packoffset(c44);\n    float4 _469_fa_rpa_by : packoffset(c45);\n    float4 _469_fa_rpa_bz : packoffset(c46);\n    float4 _469_fa_rpb_tile : packoffset(c47);\n    float4 _469_fa_rpb_pos : packoffset(c48);\n    float4 _469_fa_rpb_bx : packoffset(c49);\n    float4 _469_fa_rpb_by : packoffset(c50);\n    float4 _469_fa_rpb_bz : packoffset(c51);\n    float4 _469_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2127_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2127_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2127_fa_shadow_info[4] : packoffset(c20);\n    float4 _2127_fa_shadow_split : packoffset(c24);\n    float4 _2127_fa_shadow_cfg : packoffset(c25);\n    float4 _2127_fa_shadow_bias : packoffset(c26);\n    float4 _2127_fa_shadow_eye : packoffset(c27);\n    float4 _2127_fa_shadow_fwd : packoffset(c28);\n    float4 _2127_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5008_dark : packoffset(c0);\n    float _5008_fa_pad0 : packoffset(c0.y);\n    float _5008_fa_pad1 : packoffset(c0.z);\n    float _5008_fa_pad2 : packoffset(c0.w);\n    float _5008_skyAmount : packoffset(c1);\n    float _5008_fa_pad3 : packoffset(c1.y);\n    float _5008_fa_pad4 : packoffset(c1.z);\n    float _5008_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1398 = _469_fa_cl_info.x < 0.0f;\n    bool _1405;\n    if (!_1398)\n    {\n        _1405 = _469_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    bool _1413;\n    if (!_1405)\n    {\n        _1413 = _469_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1413 = _1405;\n    }\n    bool _1420;\n    if (!_1413)\n    {\n        _1420 = _469_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1420 = _1413;\n    }\n    bool _1427;\n    if (!_1420)\n    {\n        _1427 = _469_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1427 = _1420;\n    }\n    if (_1427)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1437 = float4(world_pos, 1.0f);\n    float _1443 = dot(_469_fa_cl_vpw, _1437);\n    if (!(_1443 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1465 = float2(dot(_469_fa_cl_vpx, _1437), dot(_469_fa_cl_vpy, _1437)) / _1443.xx;\n    int _1469 = int(_469_fa_cl_grid.x);\n    int _1473 = int(_469_fa_cl_grid.y);\n    int param = (int(_469_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_469_fa_cl_fwd.xyz, world_pos) + _469_fa_cl_fwd.w, _469_fa_cl_grid.w) / _469_fa_cl_grid.w) * _469_fa_cl_grid.z)), 0, int(_469_fa_cl_info.y) - 1) * _1473) + clamp(int(floor(((_1465.y * 0.5f) + 0.5f) * _469_fa_cl_grid.y)), 0, _1473 - 1)) * _1469)) + clamp(int(floor(((_1465.x * 0.5f) + 0.5f) * _469_fa_cl_grid.x)), 0, _1469 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1549 = fa_cluster_texel(param);\n    return int2(int(_1549.x), int(_1549.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_469_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4692 = fa_cluster_lookup(param);\n    fa_cl_slot = _4692.x;\n    fa_cl_local = _4692.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5069 = fa_linear_to_srgb(param);\n        c = _5069;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5077 = fa_srgb_to_linear(param_1);\n            c = _5077;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _349;\n    if (i.front_facing)\n    {\n        _349 = i.world_normal;\n    }\n    else\n    {\n        _349 = -i.world_normal;\n    }\n    float3 _373 = normalize(i.world_tangent.xyz - (_349 * dot(_349, i.world_tangent.xyz)));\n    float3 _401 = normalize(((_373 * m.x) + ((cross(_349, _373) * i.world_tangent.w) * m.y)) + (_349 * m.z));\n    float3 _404;\n    if (i.front_facing)\n    {\n        _404 = _401;\n    }\n    else\n    {\n        _404 = -_401;\n    }\n    return _404;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _469_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5108 = fa_tex_fix(param_2, param_3);\n    float4 _6246 = base_t;\n    _6246.x = _5108.x;\n    _6246.y = _5108.y;\n    _6246.z = _5108.z;\n    base_t = _6246;\n    float4 _5122 = (_6246 * _469_fa_base_color) * i.vertex_color;\n    float3 _6052 = i.world_normal;\n    if (_469_fa_maps.z > 0.5f)\n    {\n        float param_4 = _469_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5154 = fa_tex_fix(param_6, param_7);\n        float3 _5157 = (_5154 * 2.0f) - 1.0f.xxx;\n        float2 _5162 = _5157.xy * _469_fa_maps.x;\n        float3 _6254 = _5157;\n        _6254.x = _5162.x;\n        _6254.y = _5162.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6254;\n        _6052 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _469_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5190 = fa_tex_fix(param_12, param_13);\n    float4 _6257 = mrt;\n    _6257.x = _5190.x;\n    _6257.y = _5190.y;\n    _6257.z = _5190.z;\n    mrt = _6257;\n    float4 _5218 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _469_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5229 = fa_tex_fix(param_16, param_17);\n    float param_18 = _469_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5259 = fa_tex_fix(param_20, param_21);\n    float _6057 = _469_fa_layers_a.x;\n    float _6058 = _469_fa_layers_a.y;\n    float _6061 = _469_fa_layers_a.z;\n    float _6060 = _469_fa_layers_b.w;\n    float _6063 = _469_fa_layers_c.x;\n    if (_469_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_469_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6057 *= _5229.y;\n            _6058 *= _5229.z;\n            _6060 *= _5218.w;\n        }\n        if (_469_fa_layers_c.z > 1.5f)\n        {\n            _6061 *= mrt.x;\n            _6063 *= mrt.w;\n        }\n    }\n    Surface _6090 = { _5122.xyz, _5122.w, _6052, clamp(_469_fa_pbr.x * _5190.z, 0.0f, 1.0f), clamp(_469_fa_pbr.y * _5190.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_469_fa_maps.y * (_5229.x - 1.0f)), _469_fa_emissive.xyz + (_469_fa_model_emissive.xyz * _5259), _6057, _6058, _469_fa_layers_b.xyz, _6060, _6061, _469_fa_layers_a.w, _6063, _469_fa_layers_c.y, _469_fa_layers_d.xyz, _469_fa_tr_a.x, _469_fa_tr_a.y, _469_fa_tr_b.xyz, _469_fa_tr_a.z };\n    return _6090;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1629 = rect.zw - rect.xy;\n    float2 _1633 = _1629 * atlas;\n    float2 _1637 = ddx * _1633;\n    float2 _1641 = ddy * _1633;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1629), clamp(0.5f * log2(max(max(dot(_1637, _1637), dot(_1641, _1641)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1674 = _469_fa_counts.y < 0.5f;\n    bool _1681;\n    if (!_1674)\n    {\n        _1681 = _469_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1681 = _1674;\n    }\n    if (_1681)\n    {\n        return;\n    }\n    float3 _1687 = ddx(world_pos);\n    float3 _1690 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1694 = fa_cluster_texel(param);\n    int _1698 = int(_1694.w);\n    if (_1698 < 1)\n    {\n        return;\n    }\n    int _1708 = int(_469_fa_counts.y + 0.5f);\n    int param_1 = _1708;\n    float4 _1712 = fa_light_texel(param_1);\n    float2 _1715 = _1712.yz;\n    int _1719 = int(_1712.w);\n    int param_2 = _1708 + 1;\n    float4 _1724 = fa_light_texel(param_2);\n    float _1725 = _1724.x;\n    int _1731 = int(_469_fa_counts.w + 0.5f) - 1;\n    int _1735 = int(_1694.z);\n    float3 _2000;\n    for (int k = 0; k < _1698; k++)\n    {\n        int _1748 = _1735 + k;\n        int param_3 = _1719 + (_1748 >> 2);\n        int _1765 = (_1708 + 2) + (int(fa_light_texel(param_3)[_1748 & 3]) * 7);\n        int param_4 = _1765 + 6;\n        float4 _1770 = fa_light_texel(param_4);\n        if (((int(_1770.w + 0.5f) >> _1731) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1765;\n        float4 _1785 = fa_light_texel(param_5);\n        int param_6 = _1765 + 1;\n        float4 _1790 = fa_light_texel(param_6);\n        int param_7 = _1765 + 2;\n        float4 _1795 = fa_light_texel(param_7);\n        float3 _1798 = _1785.xyz;\n        float _1803 = dot(_1798, world_pos) + _1785.w;\n        float3 _1805 = _1790.xyz;\n        float _1810 = dot(_1805, world_pos) + _1790.w;\n        float3 _1812 = _1795.xyz;\n        float _1817 = dot(_1812, world_pos) + _1795.w;\n        bool _1822 = abs(_1803) > 0.5f;\n        bool _1830;\n        if (!_1822)\n        {\n            _1830 = abs(_1810) > 0.5f;\n        }\n        else\n        {\n            _1830 = _1822;\n        }\n        bool _1838;\n        if (!_1830)\n        {\n            _1838 = abs(_1817) > 0.5f;\n        }\n        else\n        {\n            _1838 = _1830;\n        }\n        if (_1838)\n        {\n            continue;\n        }\n        float _1853 = clamp(dot(geo_normal, normalize(_1812)) * _1770.z, 0.0f, 1.0f);\n        if (_1853 <= 0.0f)\n        {\n            continue;\n        }\n        float _1873 = (clamp((0.5f - abs(_1817)) * 10.0f, 0.0f, 1.0f) * _1853) * _1770.x;\n        float2 _1881 = float2(_1803 + 0.5f, 0.5f - _1810);\n        float2 _1891 = float2(dot(_1798, _1687), dot(_1805, _1687));\n        float2 _1901 = float2(dot(_1798, _1690), dot(_1805, _1690));\n        int param_8 = _1765 + 5;\n        float4 _1906 = fa_light_texel(param_8);\n        int param_9 = _1765 + 3;\n        float4 _1911 = fa_light_texel(param_9);\n        int param_10 = _1765 + 4;\n        float4 _1916 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1906.xyz;\n        bool _1926 = _1911.z > _1911.x;\n        if (_1926)\n        {\n            float4 param_11 = _1911;\n            float2 param_12 = _1881;\n            float2 param_13 = _1715;\n            float2 param_14 = _1891;\n            float2 param_15 = _1901;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1725 > 0.5f) && (_1725 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1952 = fa_dc_to_linear(param_16);\n                float4 _6140 = tx;\n                _6140.x = _1952.x;\n                _6140.y = _1952.y;\n                _6140.z = _1952.z;\n                tx = _6140;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1873 * tex_a) * _1906.w, 0.0f, 1.0f).xxx);\n        if (_1916.z > _1916.x)\n        {\n            float4 param_17 = _1916;\n            float2 param_18 = _1881;\n            float2 param_19 = _1715;\n            float2 param_20 = _1891;\n            float2 param_21 = _1901;\n            float4 _1996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1725 > 1.5f)\n            {\n                float3 param_22 = _1996.xyz;\n                float3 _2006 = fa_dc_to_srgb(param_22);\n                _2000 = _2006;\n            }\n            else\n            {\n                _2000 = _1996.xyz;\n            }\n            float3 _2015 = (_2000 * 2.0f) - 1.0f.xxx;\n            float2 _2020 = _2015.xy * _1770.y;\n            float3 _2042 = (normalize(_1798) * _2020.x) + (normalize(_1805) * _2020.y);\n            float3 _2045 = normalize(normal);\n            normal = normalize(lerp(_2045, normalize((_2045 * max(_2015.z, 0.0500000007450580596923828125f)) + (_2042 - (_2045 * dot(_2045, _2042)))), clamp(_1873 * (_1926 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6283;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_469_fa_cl_info.x) + int(_469_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_469_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4662;\n    if (fa_lm.z > 0.5f)\n    {\n        _4662 = 0.0f;\n    }\n    else\n    {\n        _4662 = 1.0f - clamp(_469_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4673 = _4662 < 1.0f;\n    bool _4679;\n    if (_4673)\n    {\n        int param = li;\n        _4679 = fa_light_baked(param);\n    }\n    else\n    {\n        _4679 = _4673;\n    }\n    return _4679 ? _4662 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _647 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _660 = (c - (ru * hx)) - p;\n        float3 _666 = ru * (2.0f * hx);\n        float _672 = max(dot(_666, _666), 9.9999999392252902907785028219223e-09f);\n        float _676 = dot(_660, _666);\n        float t = clamp((-_676) / _672, 0.0f, 1.0f);\n        if (_647)\n        {\n            float _691 = dot(r, _666);\n            float _697 = _672 - (_691 * _691);\n            if (abs(_697) > (9.9999997473787516355514526367188e-06f * _672))\n            {\n                t = clamp(((dot(r, _660) * _691) - _676) / _697, 0.0f, 1.0f);\n            }\n        }\n        return (p + _660) + (_666 * t);\n    }\n    float3 q = p;\n    float _729 = dot(r, axis);\n    bool _737;\n    if (_647)\n    {\n        _737 = abs(_729) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _737 = _647;\n    }\n    if (_737)\n    {\n        float _747 = dot(c - p, axis) / _729;\n        if (_747 > 0.0f)\n        {\n            q = p + (r * _747);\n        }\n    }\n    float3 _760 = q - c;\n    float2 xy = float2(dot(_760, ru), dot(_760, uu));\n    if (shape > 0.5f)\n    {\n        float _775 = length(xy);\n        if (_775 > hx)\n        {\n            xy *= (hx / _775);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _528_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _528_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _567 = dot(d, right);\n    float _571 = dot(d, up);\n    float _582;\n    if (((_567 * _567) + (_571 * _571)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _582 = atan2(_571, _567) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _582 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_582 - floor(_582)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _416 = abs(d);\n    float _418 = _416.x;\n    float _420 = _416.y;\n    bool _421 = _418 >= _420;\n    bool _429;\n    if (_421)\n    {\n        _429 = _418 >= _416.z;\n    }\n    else\n    {\n        _429 = _421;\n    }\n    int _430;\n    if (_429)\n    {\n        _430 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _445;\n        if (_420 >= _416.z)\n        {\n            _445 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _445 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _430 = _445;\n    }\n    return _430;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _813 = fa_light_base(param);\n    bool _817 = _469_fa_ambient.w > 4.5f;\n    int param_1 = _813;\n    float4 _821 = fa_light_texel(param_1);\n    int param_2 = _813 + 1;\n    float4 _826 = fa_light_texel(param_2);\n    float _829 = _826.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _841 = _817 && (_829 > 2.5f);\n    fa_light_is_area = _841;\n    bool _843 = _829 < 0.5f;\n    float3 l;\n    if (_843)\n    {\n        l = normalize(_821.xyz);\n        if (_817)\n        {\n            int param_3 = _813 + 6;\n            float4 _857 = fa_light_texel(param_3);\n            if (_857.z > 0.5f)\n            {\n                int param_4 = _813 + 4;\n                float4 _867 = fa_light_texel(param_4);\n                int param_5 = _813 + 5;\n                float4 _872 = fa_light_texel(param_5);\n                float2 param_6 = _857.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _867.xyz) * _867.w, (-dot(world_pos, _872.xyz)) * _872.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _902 = _821.xyz;\n        float3 _904 = _902 - world_pos;\n        float3 to_light = _904;\n        float _907 = length(_904);\n        float reach = _907;\n        bool front = true;\n        if (_841)\n        {\n            int param_8 = _813 + 7;\n            reach = max(_907 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _813 + 4;\n            float4 _931 = fa_light_texel(param_9);\n            int param_10 = _813 + 5;\n            float4 _936 = fa_light_texel(param_10);\n            int param_11 = _813 + 6;\n            float4 _941 = fa_light_texel(param_11);\n            float _942 = _941.w;\n            int param_12 = _813 + 2;\n            float3 _949 = normalize(fa_light_texel(param_12).xyz);\n            bool _951 = _942 > 1.5f;\n            bool _959;\n            if (!_951)\n            {\n                _959 = dot(_949, to_light) < 0.0f;\n            }\n            else\n            {\n                _959 = _951;\n            }\n            front = _959;\n            float3 r = 0.0f.xxx;\n            float3 _968 = _469_fa_camera_pos.xyz - world_pos;\n            bool _972 = dot(n, n) > 0.5f;\n            bool _980;\n            if (_972)\n            {\n                _980 = dot(_968, _968) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _980 = _972;\n            }\n            if (_980)\n            {\n                r = reflect(-normalize(_968), normalize(n));\n            }\n            float3 param_13 = _902;\n            float3 param_14 = _949;\n            float3 param_15 = _931.xyz;\n            float3 param_16 = _936.xyz;\n            float param_17 = _931.w;\n            float param_18 = _936.w;\n            float param_19 = _942;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1016 = length(to_light);\n        dist = _1016;\n        l = to_light / max(_1016, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1030 = reach / max(_821.w, 0.001000000047497451305389404296875f);\n        float _1036 = clamp(1.0f - (_1030 * _1030), 0.0f, 1.0f);\n        float _1038;\n        if (front)\n        {\n            _1038 = _1036 * _1036;\n        }\n        else\n        {\n            _1038 = 0.0f;\n        }\n        atten = _1038;\n        bool _1049 = _829 < 2.5f;\n        if ((_829 > 1.5f) && _1049)\n        {\n            int param_22 = _813 + 2;\n            float4 _1057 = fa_light_texel(param_22);\n            float _1067 = _1057.w;\n            int param_23 = _813 + 3;\n            float4 _1072 = fa_light_texel(param_23);\n            float _1073 = _1072.x;\n            float cos_inner = _1073;\n            if (_1073 > 1.5f)\n            {\n                cos_inner = lerp(_1067, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1067, cos_inner, dot(-l, normalize(_1057.xyz)));\n        }\n        if (_817 && (_829 < 1.5f))\n        {\n            int param_24 = _813 + 6;\n            float4 _1097 = fa_light_texel(param_24);\n            if (_1097.z > 0.5f)\n            {\n                float3 _1105 = -to_light;\n                int param_25 = _813 + 4;\n                int param_26 = _813 + 5;\n                float3 _1119 = fa_light_texel(param_25).xyz;\n                float3 _1123 = fa_light_texel(param_26).xyz;\n                float3 _1132 = float3(dot(_1105, _1119), dot(_1105, _1123), dot(_1105, cross(_1119, _1123)));\n                float3 param_27 = _1132;\n                int _1136 = fa_cube_face(param_27);\n                int param_28 = _1136;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1163 = float2(dot(_1132, cross(param_29, param_30)), dot(_1132, param_30)) / max(dot(_1132, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1167 = _1136 / 3;\n                float2 param_31 = _1097.xy + (float2(float(_1136 - (_1167 * 3)), float(_1167)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1163.x), 0.5f - (0.5f * _1163.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _813 + 7;\n            float4 _1197 = fa_light_texel(param_33);\n            if (_1197.z > 0.5f)\n            {\n                int param_34 = _813 + 2;\n                int param_35 = _813 + 4;\n                int param_36 = _813 + 5;\n                float2 param_37 = _1197.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_817 && _1049)\n            {\n                int param_42 = _813 + 6;\n                float4 _1244 = fa_light_texel(param_42);\n                int param_43 = _813 + 7;\n                float4 _1249 = fa_light_texel(param_43);\n                bool _1252 = _1244.z > 0.5f;\n                bool _1259;\n                if (!_1252)\n                {\n                    _1259 = _1249.z > 0.5f;\n                }\n                else\n                {\n                    _1259 = _1252;\n                }\n                if (_1259)\n                {\n                    int param_44 = _813 + 2;\n                    float4 _1266 = fa_light_texel(param_44);\n                    float3 _1270 = normalize(_1266.xyz);\n                    int param_45 = _813 + 4;\n                    float4 _1275 = fa_light_texel(param_45);\n                    int param_46 = _813 + 5;\n                    float4 _1280 = fa_light_texel(param_46);\n                    if (_1252)\n                    {\n                        float3 _1288 = -to_light;\n                        float _1295 = _1266.w;\n                        float _1311 = 0.5f / max(dot(_1288, _1270) * (sqrt(max(1.0f - (_1295 * _1295), 0.0f)) / max(_1295, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1244.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1288, _1275.xyz) * _1311), 0.5f - (dot(_1288, _1280.xyz) * _1311));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1249.z > 0.5f)\n                    {\n                        float2 param_49 = _1249.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1270;\n                        float3 param_52 = _1275.xyz;\n                        float3 param_53 = _1280.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5858 = _826.xyz * atten;\n    if (_817)\n    {\n        _5858 *= fa_light_tint;\n    }\n    int _1380;\n    if (_843)\n    {\n        _1380 = 0;\n    }\n    else\n    {\n        _1380 = ((_829 > 1.5f) && (_829 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5869 = { l, _5858, atten, 1.0f, dist, _1380 };\n    return _5869;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4891 = n < 0;\n    bool _4898;\n    if (!_4891)\n    {\n        _4898 = n >= fa_light_count();\n    }\n    else\n    {\n        _4898 = _4891;\n    }\n    if (_4898)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4906 = fa_cl_light(param);\n    int param_1 = _4906;\n    float _4910 = fa_baked_keep(param_1);\n    if (_4910 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4906;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4926 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6040 = { _4926.direction, _4926.color * _4910, _4926.attenuation * _4910, _4926.shadow, _4926._distance, _4926.type };\n    return _6040;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2174 = fa_shadow_depth(param, param_1);\n    float _2178;\n    if (conv.x < 0.5f)\n    {\n        _2178 = _2174;\n    }\n    else\n    {\n        _2178 = (conv.y * conv.z) / (conv.z - (_2174 * (conv.z - conv.y)));\n    }\n    return _2178;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2105 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2105), sin(_2105)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2224 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2253 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2224;\n            float2 _2272 = fa_shadow_vogel(param_3, param_4, param_5) * _2253;\n            float2 param_6 = uv + (_2272 * _2127_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2284 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2284 < (zr - (length(_2272) * plane)))\n            {\n                sum += _2284;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2310 = sum / cnt;\n        float _2320;\n        if (k < 0.0f)\n        {\n            _2320 = (-k) / max(_2310, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2320 = k;\n        }\n        radius = clamp(((max(zr - _2310, 0.0f) * unit) * _2320) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2342 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2342; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2342;\n        float param_11 = _2224;\n        float2 _2361 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2361 * _2127_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2361) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2342);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2561 = _469_fa_pbr.z < 0.5f;\n    bool _2568;\n    if (!_2561)\n    {\n        _2568 = _2127_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2568 = _2561;\n    }\n    if (_2568)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2127_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2581 = fa_light_texel(param);\n    float _2582 = _2581.x;\n    if (_2582 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2591 = int(_2582 + 0.5f);\n    int param_1 = _2591;\n    float4 _2595 = fa_light_texel(param_1);\n    int param_2 = _2591 + 1;\n    float4 _2600 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2603 = _2595.y;\n    if (_2603 > 0.0f)\n    {\n        float _2620 = 1.0f - smoothstep(0.75f * _2603, _2603, length(world - _2127_fa_shadow_eye.xyz));\n        fade = _2620;\n        if (_2620 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2595.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2644 = (_2591 + 2) + (face * 6);\n    int param_4 = _2644;\n    int param_5 = _2644 + 1;\n    int param_6 = _2644 + 3;\n    float4 _2658 = fa_light_texel(param_6);\n    int param_7 = _2644 + 4;\n    float4 _2663 = fa_light_texel(param_7);\n    int param_8 = _2644 + 5;\n    float4 _2668 = fa_light_texel(param_8);\n    float _2680 = _2668.x * max(dot(_2658, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2685 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2708 = clamp(dot(n, _2658.xyz), -1.0f, 1.0f);\n    float _2727 = min(sqrt(1.0f - (_2708 * _2708)) / max(abs(dot(n, world - lpos)) / max(dot(_2658, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2730 = _2600.y;\n    float _2732;\n    if (_2730 > 0.0f)\n    {\n        _2732 = _2730;\n    }\n    else\n    {\n        _2732 = 1.5f * _2680;\n    }\n    float4 _2752 = float4(world + (n * (_2732 * sqrt(1.0f - (_2685 * _2685)))), 1.0f);\n    float _2756 = dot(_2658, _2752);\n    float _2759 = _2668.y;\n    if (_2756 < _2759)\n    {\n        return 1.0f;\n    }\n    float2 _2774 = float2(dot(fa_light_texel(param_4), _2752), dot(fa_light_texel(param_5), _2752)) / _2756.xx;\n    float _2776 = _2774.x;\n    bool _2779 = _2776 < _2663.x;\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2776 > _2663.z;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2774.y < _2663.y;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    bool _2806;\n    if (!_2797)\n    {\n        _2806 = _2774.y > _2663.w;\n    }\n    else\n    {\n        _2806 = _2797;\n    }\n    if (_2806)\n    {\n        return 1.0f;\n    }\n    float _2812 = _2600.x;\n    float _2814;\n    if (_2812 > 0.0f)\n    {\n        _2814 = _2812;\n    }\n    else\n    {\n        _2814 = 1.5f * _2680;\n    }\n    float2 param_9 = _2774;\n    float4 param_10 = _2663;\n    float param_11 = _2756 - (_2814 * (1.0f + (0.5f * _2727)));\n    float param_12 = _2680;\n    float param_13 = 1.0f;\n    float param_14 = _2668.z * 0.25f;\n    float param_15 = (_2680 * min(_2727, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2759, _2668.z);\n    int param_17 = int(_2595.z + 0.5f);\n    float param_18 = _2595.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2117;\n    if (i == 0)\n    {\n        _2117 = _2127_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2133;\n        if (i == 1)\n        {\n            _2133 = _2127_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2141;\n            if (i == 2)\n            {\n                _2141 = _2127_fa_shadow_split.z;\n            }\n            else\n            {\n                _2141 = _2127_fa_shadow_split.w;\n            }\n            _2133 = _2141;\n        }\n        _2117 = _2133;\n    }\n    return _2117;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2403 = max(_2127_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2408 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2414 = sqrt(1.0f - (_2408 * _2408));\n    float _2421 = min(_2414 / max(_2408, 0.20000000298023223876953125f), 4.0f);\n    float _2426;\n    if (_2127_fa_shadow_bias.y > 0.0f)\n    {\n        _2426 = _2127_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2426 = 1.5f * _2127_fa_shadow_info[ci].x;\n    }\n    float4 _2451 = mul(float4(world + (n * (_2426 * _2414)), 1.0f), _2127_fa_shadow_mat[ci]);\n    float _2458 = _2451.x;\n    bool _2461 = _2458 < _2127_fa_shadow_rect[ci].x;\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2458 > _2127_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2451.y < _2127_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2488;\n    if (!_2479)\n    {\n        _2488 = _2451.y > _2127_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2488 = _2479;\n    }\n    bool _2495;\n    if (!_2488)\n    {\n        _2495 = _2451.z > 1.0f;\n    }\n    else\n    {\n        _2495 = _2488;\n    }\n    if (_2495)\n    {\n        return -1.0f;\n    }\n    float _2503;\n    if (_2127_fa_shadow_bias.x > 0.0f)\n    {\n        _2503 = _2127_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2503 = 1.5f * _2127_fa_shadow_info[ci].x;\n    }\n    float2 param = _2451.xy;\n    float4 param_1 = _2127_fa_shadow_rect[ci];\n    float param_2 = _2451.z - ((_2503 * (1.0f + (0.5f * _2421))) / _2403);\n    float param_3 = _2127_fa_shadow_info[ci].x;\n    float param_4 = _2403;\n    float param_5 = _2403 * 0.25f;\n    float param_6 = ((_2127_fa_shadow_info[ci].x * min(_2421, 3.0f)) * 0.5f) / _2403;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2127_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2127_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_469_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2881 = int(_2127_fa_shadow_cfg.x + 0.5f);\n    if (_2881 < 1)\n    {\n        return 1.0f;\n    }\n    float _2896 = dot(world - _2127_fa_shadow_eye.xyz, _2127_fa_shadow_fwd.xyz);\n    int param = _2881 - 1;\n    if (_2896 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2908 = _2881 > 1;\n    bool _2915;\n    if (_2908)\n    {\n        _2915 = _2896 > _2127_fa_shadow_split.x;\n    }\n    else\n    {\n        _2915 = _2908;\n    }\n    if (_2915)\n    {\n        ci = 1;\n    }\n    bool _2919 = _2881 > 2;\n    bool _2926;\n    if (_2919)\n    {\n        _2926 = _2896 > _2127_fa_shadow_split.y;\n    }\n    else\n    {\n        _2926 = _2919;\n    }\n    if (_2926)\n    {\n        ci = 2;\n    }\n    bool _2930 = _2881 > 3;\n    bool _2937;\n    if (_2930)\n    {\n        _2937 = _2896 > _2127_fa_shadow_split.z;\n    }\n    else\n    {\n        _2937 = _2930;\n    }\n    if (_2937)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2881)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2963 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2963;\n        if (_2963 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2127_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2988;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2988 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2988 = _2127_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3007 = _2127_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2988, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3018 = clamp((_2896 - (fa_shadow_split_at(param_7) - _3007)) / _3007, 0.0f, 1.0f);\n        if (_3018 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2881)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3039 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3039;\n                if (_3039 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3018);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4406 = _469_fa_ct_a.x < 0.5f;\n    bool _4413;\n    if (!_4406)\n    {\n        _4413 = _2127_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4413 = _4406;\n    }\n    if (_4413)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2127_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4426 = fa_light_texel(param);\n    float _4427 = _4426.y;\n    float len = _4427;\n    if (_4427 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4439 = length(world - _469_fa_camera_pos.xyz);\n    float _4449 = 1.0f - smoothstep(0.5f * _469_fa_ct_b.x, _469_fa_ct_b.x, _4439);\n    if (_4449 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4455 = len;\n    float _4458 = min(_4455, 0.89999997615814208984375f * dist);\n    len = _4458;\n    float _4463 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4439);\n    float _4468 = _4463 + (0.5f * _4458);\n    float3 _4474 = world + (gn * _4463);\n    float _4476 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4540;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4491 = (float(k) + _4476) * 0.083333335816860198974609375f;\n        float3 _4499 = _4474 + (l * (_4491 * len));\n        float4 _4505 = float4(_4499, 1.0f);\n        float _4511 = dot(_469_fa_ct_vpw, _4505);\n        if (_4511 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4531 = float2(dot(_469_fa_ct_vpx, _4505), dot(_469_fa_ct_vpy, _4505)) / _4511.xx;\n        float _4535 = _4531.x * 0.5f;\n        float _4536 = _4535 + 0.5f;\n        if (_469_fa_ct_a.y > 0.5f)\n        {\n            _4540 = (_4531.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4540 = 0.5f - (_4531.y * 0.5f);\n        }\n        bool _4556 = _4536 < 0.0f;\n        bool _4563;\n        if (!_4556)\n        {\n            _4563 = _4536 >= 1.0f;\n        }\n        else\n        {\n            _4563 = _4556;\n        }\n        bool _4570;\n        if (!_4563)\n        {\n            _4570 = _4540 < 0.0f;\n        }\n        else\n        {\n            _4570 = _4563;\n        }\n        bool _4577;\n        if (!_4570)\n        {\n            _4577 = _4540 >= 1.0f;\n        }\n        else\n        {\n            _4577 = _4570;\n        }\n        if (_4577)\n        {\n            break;\n        }\n        float4 _4596 = fa_screen_tex.Load(int3(int2(float2(_4536, _4540) * _469_fa_ct_a.zw), 0));\n        if (_4596.w < 0.5f)\n        {\n            continue;\n        }\n        float _4615 = (dot(_469_fa_ct_fwd.xyz, _4499) + _469_fa_ct_fwd.w) - _4596.x;\n        if ((_4615 > _4463) && (_4615 < _4468))\n        {\n            occ = max(occ, (1.0f - (_4491 * _4491)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4536, 0.5f - _4535), min(_4540, 1.0f - _4540))));\n        }\n    }\n    return 1.0f - (occ * _4449);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4718 = fa_baked_keep(param);\n    if (_4718 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6002 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6002;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4744 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6004 = _4744.color;\n    float _6005 = _4744.attenuation;\n    float _6006 = _4744.shadow;\n    bool _4747 = _4744.type == 0;\n    if (_4747 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4744.direction;\n        float _4758 = fa_shadow_factor(param_5, param_6);\n        _6006 = _4758;\n        _6004 *= _4758;\n    }\n    else\n    {\n        bool _4769 = _4744.type != 0;\n        bool _4775;\n        if (_4769)\n        {\n            _4775 = _6005 > 0.0f;\n        }\n        else\n        {\n            _4775 = _4769;\n        }\n        if (_4775)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4744.direction;\n            float _4794 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6006 = _4794;\n            _6004 *= _4794;\n        }\n    }\n    bool _4804 = _469_fa_ct_a.x > 0.5f;\n    bool _4810;\n    if (_4804)\n    {\n        _4810 = _6005 > 0.0f;\n    }\n    else\n    {\n        _4810 = _4804;\n    }\n    if (_4810)\n    {\n        float _4817;\n        if (_4747)\n        {\n            _4817 = 1000000000.0f;\n        }\n        else\n        {\n            _4817 = _4744._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4744.direction;\n        float param_18 = _4817;\n        float _4835 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6006 *= _4835;\n        _6004 *= _4835;\n    }\n    float _4848 = _6005;\n    float _4849 = _4848 * _4718;\n    _6005 = _4849;\n    float3 _4853 = _6004;\n    float3 _4854 = _4853 * _4718;\n    _6004 = _4854;\n    LightSample _6021 = { _4744.direction, _4854, _4849, _6006, _4744._distance, _4744.type };\n    return _6021;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4865 = n < 0;\n    bool _4872;\n    if (!_4865)\n    {\n        _4872 = n >= fa_light_count();\n    }\n    else\n    {\n        _4872 = _4865;\n    }\n    if (_4872)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4887 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4887;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3797 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3805 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3808 = int(_3797);\n    int _3811 = int(_3805);\n    float _3821 = _3805 - float(_3811);\n    int _3877 = (_3808 * 9) + _3811;\n    int _3897 = ((_3808 + 1) * 9) + _3811;\n    return lerp(lerp(_3872[_3877], _3872[_3877 + 1], _3821), lerp(_3872[_3897], _3872[_3897 + 1], _3821), _3797 - float(_3808));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5870 = false;\n    float _5871 = 1.0f;\n    float _5872 = 1.0f;\n    float _5873 = 1.0f;\n    float _5874 = 0.0f;\n    float _5875 = 0.0f;\n    float _5876 = 0.0f;\n    float _5877 = 0.0f;\n    float _5879 = 1.0f;\n    bool _5880 = false;\n    float3 _5881 = 0.0f.xxx;\n    float _5882 = 1.0f;\n    float _5883 = 1.0f;\n    float _5884 = 1.0f;\n    float _5885 = 0.0f;\n    float _5886 = 0.0f;\n    float3 _5887 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5888 = float3(0.0f, 0.0f, 1.0f);\n    float _5889 = 1.0f;\n    float _5890 = 1.0f;\n    float _3948 = clamp(s.specular, 0.0f, 1.0f);\n    float _3952 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3957 = (_3948 != 1.0f) || (_3952 != 1.5f);\n    bool _3966;\n    if (!_3957)\n    {\n        _3966 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3966 = _3957;\n    }\n    if (_3966)\n    {\n        float _3974 = (_3952 - 1.0f) / (_3952 + 1.0f);\n        f0 = lerp(min((_3974 * _3974).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3948, s.albedo, metallic.xxx);\n        _5871 = lerp(_3948, 1.0f, metallic);\n        _5870 = true;\n    }\n    float _4001 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4001 > 0.0f)\n    {\n        float _4009 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5874 = _4001;\n        _5875 = _4009;\n        float _4016 = _4009 * _4009;\n        _5876 = _4016;\n        _5877 = _4016 * _4016;\n        float _4028 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5879 = _4028;\n        _5872 = 1.0f - (_4001 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4028, 0.0f, 1.0f), 5.0f))));\n        _5870 = true;\n    }\n    float3 _4047 = max(s.sheen_color, 0.0f.xxx);\n    float _4056 = max(_4047.x, max(_4047.y, _4047.z));\n    if (_4056 > 0.0f)\n    {\n        float _4064 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5880 = true;\n        _5881 = _4047;\n        _5882 = _4064;\n        _5883 = _4064 * _4064;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4064;\n        float _4081 = fa_sheen_albedo(param, param_1);\n        _5885 = _4081;\n        _5884 = 1.0f - min(_4056 * _4081, 1.0f);\n        _5870 = true;\n    }\n    _5873 = _5872 * _5884;\n    float _4100 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4100 != 0.0f)\n    {\n        float3 _4115 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4115;\n        if (dot(_4115, _4115) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4127 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4127.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4127.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4127.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4131 = t;\n        float3 _4132 = normalize(_4131);\n        t = _4132;\n        float3 _4157 = normalize((_4132 * cos(s.anisotropy_rotation)) + ((cross(n, _4132) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5887 = _4157;\n        _5888 = cross(n, _4157);\n        float _4167 = roughness * roughness;\n        float _4173 = lerp(_4167, 1.0f, _4100 * _4100);\n        bool _4175 = _4100 > 0.0f;\n        _5889 = _4175 ? _4173 : _4167;\n        _5890 = _4175 ? _4167 : _4173;\n        _5886 = _4100;\n        _5870 = true;\n    }\n    FaLayers _5912 = { _5870, _5871, _5872, _5873, _5874, _5875, _5876, _5877, i.world_normal, _5879, _5880, _5881, _5882, _5883, _5884, _5885, _5886, _5887, _5888, _5889, _5890 };\n    return _5912;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3729 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3732 = _3729.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3732 * _3732, exp2((-9.27999973297119140625f) * ndv)) * _3732) + _3729.y)) + _3729.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3165 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3168 = _3165.x;\n    float _3170 = _3165.z;\n    float2 e = float2(_3168, _3170);\n    if (_3165.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3170)) * ((_3168 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3168)) * ((_3170 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3204_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3204_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3217;\n    if (lv == 0)\n    {\n        _3217 = 0.0f;\n    }\n    else\n    {\n        _3217 = res + 2.0f;\n    }\n    float _3227;\n    if (lv == 0)\n    {\n        _3227 = 0.0f;\n    }\n    else\n    {\n        _3227 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3217, _3227)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3272;\n    if (res > 64.5f)\n    {\n        _3272 = 5.0f;\n    }\n    else\n    {\n        _3272 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3287 = clamp(rough, 0.0f, 1.0f) * (_3272 - 1.0f);\n    int _3294 = int(min(floor(_3287), _3272 - 2.0f));\n    float _3299 = _3287 - float(_3294);\n    float3 param = d;\n    float2 _3303 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3294;\n    float2 param_4 = _3303;\n    float3 _3313 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3299 < 0.00200000009499490261077880859375f)\n    {\n        return _3313;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3294 + 1;\n    float2 param_8 = _3303;\n    return lerp(_3313, fa_probe_level(param_5, param_6, param_7, param_8), _3299.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3351 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3358 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3365 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3371 = dot(bx.xyz, d);\n    float _3375 = dot(by.xyz, d);\n    float _3379 = dot(bz.xyz, d);\n    float _3385;\n    if (_3371 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3385 = (1.0f - _3351) / _3371;\n    }\n    else\n    {\n        float _3399;\n        if (_3371 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3399 = ((-1.0f) - _3351) / _3371;\n        }\n        else\n        {\n            _3399 = 1000000015047466219876688855040.0f;\n        }\n        _3385 = _3399;\n    }\n    float tx = _3385;\n    float _3416;\n    if (_3375 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3416 = (1.0f - _3358) / _3375;\n    }\n    else\n    {\n        float _3429;\n        if (_3375 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3429 = ((-1.0f) - _3358) / _3375;\n        }\n        else\n        {\n            _3429 = 1000000015047466219876688855040.0f;\n        }\n        _3416 = _3429;\n    }\n    float ty = _3416;\n    float _3445;\n    if (_3379 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3445 = (1.0f - _3365) / _3379;\n    }\n    else\n    {\n        float _3458;\n        if (_3379 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3458 = ((-1.0f) - _3365) / _3379;\n        }\n        else\n        {\n            _3458 = 1000000015047466219876688855040.0f;\n        }\n        _3445 = _3458;\n    }\n    float _3470 = tx;\n    float _3473 = (_3470 > 0.0f) ? _3470 : 1000000015047466219876688855040.0f;\n    tx = _3473;\n    float _3474 = ty;\n    float _3477 = (_3474 > 0.0f) ? _3474 : 1000000015047466219876688855040.0f;\n    ty = _3477;\n    float _3487 = min(_3473, min(_3477, (_3445 > 0.0f) ? _3445 : 1000000015047466219876688855040.0f));\n    if (_3487 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3503 = (fa_world_pos + (d * _3487)) - posw.xyz;\n    float3 _3508;\n    if (dot(_3503, _3503) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3508 = normalize(_3503);\n    }\n    else\n    {\n        _3508 = d;\n    }\n    return _3508;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3554 = (1.0f - _469_fa_rpa_tile.w) - _469_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3554 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_469_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _469_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3584 = rough * rough;\n            float _3615 = 0.60000002384185791015625f * _3584;\n            base = lerp(lerp(_469_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_469_fa_env_horizon.xyz, _469_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3584)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3615, 0.0500000007450580596923828125f + _3615, d.y).xxx), ((_469_fa_env_sky.xyz + _469_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3584 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3554;\n    }\n    if (_469_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _469_fa_rpa_tile;\n        float4 param_5 = _469_fa_rpa_pos;\n        float4 param_6 = _469_fa_rpa_bx;\n        float4 param_7 = _469_fa_rpa_by;\n        float4 param_8 = _469_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3674 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3674 * _469_fa_rpa_tile.w);\n    }\n    if (_469_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _469_fa_rpb_tile;\n        float4 param_12 = _469_fa_rpb_pos;\n        float4 param_13 = _469_fa_rpb_bx;\n        float4 param_14 = _469_fa_rpb_by;\n        float4 param_15 = _469_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3706 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3706 * _469_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4208;\n        if (L.aniso >= 0.0f)\n        {\n            _4208 = L.b;\n        }\n        else\n        {\n            _4208 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4208, v), _4208), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4241 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4241.x) + (L.f90.xxx * _4241.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4296 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4296.x) + _4296.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3771 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3771.x) + _3771.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4335 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4339 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4346 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4335.xxx);\n    float3 f0 = _4346;\n    float3 _4350 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4350;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4335;\n    float param_5 = _4339;\n    float3 param_6 = _4346;\n    FaLayers _4367 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4367.on)\n    {\n        FaLayers param_7 = _4367;\n        float3 param_8 = _4350;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4339;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _4350;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _4339;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4957 = fa_light_unshadowed(param, param_1);\n        float _4965 = dot(_4957.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4965 > bestPower)\n        {\n            bestPower = _4965;\n            best = n;\n        }\n    }\n    float3 lit = (_469_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4994 = fa_light(param_2, param_3);\n        float _5002;\n        if (dot(s.normal, _4994.direction) > 0.5f)\n        {\n            _5002 = 1.0f;\n        }\n        else\n        {\n            _5002 = _5008_dark;\n        }\n        lit += ((s.albedo * _4994.color) * _5002);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5008_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2127_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3063 = int(_2127_fa_shadow_cfg.x + 0.5f);\n    float _3073 = dot(world - _2127_fa_shadow_eye.xyz, _2127_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3078 = _3063 > 0;\n    bool _3087;\n    if (_3078)\n    {\n        int param = _3063 - 1;\n        _3087 = _3073 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3087 = _3078;\n    }\n    if (_3087)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3093 = _3063 > 1;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3073 > _2127_fa_shadow_split.x;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3106 = _3063 > 2;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3073 > _2127_fa_shadow_split.y;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3119 = _3063 > 3;\n        bool _3126;\n        if (_3119)\n        {\n            _3126 = _3073 > _2127_fa_shadow_split.z;\n        }\n        else\n        {\n            _3126 = _3119;\n        }\n        if (_3126)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5724 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5724 = -_5724;\n    }\n    float3 _5395 = normalize(_469_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5737 = { fa_world_pos, _5724, fa_world_tangent, fa_uv, fa_vertex_color, _5395, gl_FrontFacing };\n    SurfaceInput param_1 = _5737;\n    Surface _5403 = fa_standard_surface(param_1);\n    float3 _5755 = _5403.albedo;\n    float _5756 = _5403.alpha;\n    float3 _5757 = _5403.normal;\n    float _5758 = _5403.metallic;\n    float _5759 = _5403.roughness;\n    float _5760 = _5403.occlusion;\n    float3 _5761 = _5403.emission;\n    float _5762 = _5403.clearcoat;\n    float _5763 = _5403.clearcoat_roughness;\n    float3 _5764 = _5403.sheen_color;\n    float _5765 = _5403.sheen_roughness;\n    float _5766 = _5403.anisotropy;\n    float _5767 = _5403.anisotropy_rotation;\n    float _5768 = _5403.specular;\n    float _5769 = _5403.ior;\n    float3 _5770 = _5403.specular_color;\n    float _5771 = _5403.transmission;\n    float _5772 = _5403.thickness;\n    float3 _5773 = _5403.attenuation_color;\n    float _5774 = _5403.attenuation_distance;\n    SurfaceInput _5745 = { fa_world_pos, _5724, fa_world_tangent, fa_uv, fa_vertex_color, _5395, gl_FrontFacing };\n    SurfaceInput param_2 = _5745;\n    Surface param_3 = _5403;\n    surface(param_2, param_3);\n    _5755 = param_3.albedo;\n    _5756 = param_3.alpha;\n    _5757 = param_3.normal;\n    _5758 = param_3.metallic;\n    _5759 = param_3.roughness;\n    _5760 = param_3.occlusion;\n    _5761 = param_3.emission;\n    _5762 = param_3.clearcoat;\n    _5763 = param_3.clearcoat_roughness;\n    _5764 = param_3.sheen_color;\n    _5765 = param_3.sheen_roughness;\n    _5766 = param_3.anisotropy;\n    _5767 = param_3.anisotropy_rotation;\n    _5768 = param_3.specular;\n    _5769 = param_3.ior;\n    _5770 = param_3.specular_color;\n    _5771 = param_3.transmission;\n    _5772 = param_3.thickness;\n    _5773 = param_3.attenuation_color;\n    _5774 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5724;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5755 = param_6;\n    _5757 = param_7;\n    float3 result;\n    if (_469_fa_emissive.w > 0.5f)\n    {\n        result = _5755;\n    }\n    else\n    {\n        float3 _5442 = _5757;\n        float3 _5443 = normalize(_5442);\n        _5757 = _5443;\n        SurfaceInput _5753 = { fa_world_pos, _5724, fa_world_tangent, fa_uv, fa_vertex_color, _5395, gl_FrontFacing };\n        SurfaceInput param_8 = _5753;\n        Surface _5856 = { _5755, _5756, _5443, _5758, _5759, _5760, _5761, _5762, _5763, _5764, _5765, _5766, _5767, _5768, _5769, _5770, _5771, _5772, _5773, _5774 };\n        Surface param_9 = _5856;\n        float3 _5454 = lighting(param_8, param_9);\n        result = _5454;\n    }\n    float3 _5458 = result;\n    float3 _5459 = _5458 + _5761;\n    result = _5459;\n    float3 param_10 = _5459;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5468 = _469_fa_fog.w > 0.0f;\n    bool _5475;\n    if (!_5468)\n    {\n        _5475 = _469_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5475 = _5468;\n    }\n    if (_5475)\n    {\n        float3 _5484 = fa_world_pos - _469_fa_camera_pos.xyz;\n        float _5490 = dot(_5484, _469_fa_fog_c.xyz);\n        bool _5494 = _469_fa_fog_c.w > 0.5f;\n        float _5495;\n        if (_5494)\n        {\n            _5495 = _5490;\n        }\n        else\n        {\n            _5495 = length(_5484);\n        }\n        float _5507 = _5495 - _469_fa_fog_b.x;\n        if (_5507 > 0.0f)\n        {\n            float _5516 = _469_fa_fog.w * _5507;\n            float tau = _5516 * _5516;\n            if (_469_fa_fog_b.y > 0.0f)\n            {\n                float _5532;\n                if (_5494)\n                {\n                    _5532 = fa_world_pos.y - (_469_fa_fog_c.y * _5490);\n                }\n                else\n                {\n                    _5532 = _469_fa_camera_pos.y;\n                }\n                float _5553 = lerp(_5532, fa_world_pos.y, clamp(_469_fa_fog_b.x / _5495, 0.0f, 1.0f));\n                float _5557 = fa_world_pos.y - _5553;\n                float _5562 = _5553 - _469_fa_fog_b.z;\n                float _5567 = fa_world_pos.y - _469_fa_fog_b.z;\n                bool _5570 = _5562 <= 0.0f;\n                bool _5571 = !_5570;\n                bool _5577;\n                if (_5571)\n                {\n                    _5577 = _469_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5577 = _5570;\n                }\n                float _5578;\n                if (_5577)\n                {\n                    _5578 = _469_fa_fog_b.y;\n                }\n                else\n                {\n                    _5578 = _469_fa_fog_b.y * exp(-min(_469_fa_fog_b.w * _5562, 80.0f));\n                }\n                bool _5605;\n                if (_5571)\n                {\n                    _5605 = _469_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5605 = _5570;\n                }\n                float _5606;\n                if (_5605)\n                {\n                    _5606 = _469_fa_fog_b.y * _5562;\n                }\n                else\n                {\n                    _5606 = (_469_fa_fog_b.y * (1.0f - exp(-min(_469_fa_fog_b.w * _5562, 80.0f)))) / _469_fa_fog_b.w;\n                }\n                bool _5631 = _5567 <= 0.0f;\n                bool _5638;\n                if (!_5631)\n                {\n                    _5638 = _469_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5638 = _5631;\n                }\n                float _5639;\n                if (_5638)\n                {\n                    _5639 = _469_fa_fog_b.y * _5567;\n                }\n                else\n                {\n                    _5639 = (_469_fa_fog_b.y * (1.0f - exp(-min(_469_fa_fog_b.w * _5567, 80.0f)))) / _469_fa_fog_b.w;\n                }\n                float _5666;\n                if (abs(_5557) < 0.001000000047497451305389404296875f)\n                {\n                    _5666 = _5578;\n                }\n                else\n                {\n                    _5666 = (_5639 - _5606) / _5557;\n                }\n                tau += (_5507 * max(_5666, 0.0f));\n            }\n            result = lerp(result, _469_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5756);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_469",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2127",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5008",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n    float4 _215_fa_atlas : packoffset(c41);\n    float4 _215_fa_rpa_tile : packoffset(c42);\n    float4 _215_fa_rpa_pos : packoffset(c43);\n    float4 _215_fa_rpa_bx : packoffset(c44);\n    float4 _215_fa_rpa_by : packoffset(c45);\n    float4 _215_fa_rpa_bz : packoffset(c46);\n    float4 _215_fa_rpb_tile : packoffset(c47);\n    float4 _215_fa_rpb_pos : packoffset(c48);\n    float4 _215_fa_rpb_bx : packoffset(c49);\n    float4 _215_fa_rpb_by : packoffset(c50);\n    float4 _215_fa_rpb_bz : packoffset(c51);\n    float4 _215_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _831 = base_t;\n    _831.x = _227.x;\n    _831.y = _227.y;\n    _831.z = _227.z;\n    base_t = _831;\n    float4 _243 = (_831 * _215_fa_base_color) * i.vertex_color;\n    float3 _786 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _839 = _281;\n        _839.x = _286.x;\n        _839.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _842 = mrt;\n    _842.x = _315.x;\n    _842.y = _315.y;\n    _842.z = _315.z;\n    mrt = _842;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _791 = _215_fa_layers_a.x;\n    float _792 = _215_fa_layers_a.y;\n    float _795 = _215_fa_layers_a.z;\n    float _794 = _215_fa_layers_b.w;\n    float _797 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _791 *= _357.y;\n            _792 *= _357.z;\n            _794 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    Surface _824 = { _243.xyz, _243.w, _786, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _791, _792, _215_fa_layers_b.xyz, _794, _795, _215_fa_layers_a.w, _797, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _824;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _694 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _694;\n    SurfaceInput _702 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _702;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_215",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n    float4 _215_fa_atlas : packoffset(c41);\n    float4 _215_fa_rpa_tile : packoffset(c42);\n    float4 _215_fa_rpa_pos : packoffset(c43);\n    float4 _215_fa_rpa_bx : packoffset(c44);\n    float4 _215_fa_rpa_by : packoffset(c45);\n    float4 _215_fa_rpa_bz : packoffset(c46);\n    float4 _215_fa_rpb_tile : packoffset(c47);\n    float4 _215_fa_rpb_pos : packoffset(c48);\n    float4 _215_fa_rpb_bx : packoffset(c49);\n    float4 _215_fa_rpb_by : packoffset(c50);\n    float4 _215_fa_rpb_bz : packoffset(c51);\n    float4 _215_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _831 = base_t;\n    _831.x = _227.x;\n    _831.y = _227.y;\n    _831.z = _227.z;\n    base_t = _831;\n    float4 _243 = (_831 * _215_fa_base_color) * i.vertex_color;\n    float3 _786 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _839 = _281;\n        _839.x = _286.x;\n        _839.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _842 = mrt;\n    _842.x = _315.x;\n    _842.y = _315.y;\n    _842.z = _315.z;\n    mrt = _842;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _791 = _215_fa_layers_a.x;\n    float _792 = _215_fa_layers_a.y;\n    float _795 = _215_fa_layers_a.z;\n    float _794 = _215_fa_layers_b.w;\n    float _797 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _791 *= _357.y;\n            _792 *= _357.z;\n            _794 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    Surface _824 = { _243.xyz, _243.w, _786, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _791, _792, _215_fa_layers_b.xyz, _794, _795, _215_fa_layers_a.w, _797, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _824;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _681 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _694 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _694;\n    SurfaceInput _702 = { fa_world_pos, _681, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _702;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_215",
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
