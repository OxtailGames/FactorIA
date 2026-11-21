{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ae26515a48b1a8d2e7a58b8583b7398bc5ad5b1e5314aaacf65f28e91c149fe7",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _269 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _269;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _276 = _160.world_pos;\n    fa_world_pos = _276;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_276, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4353[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _653_fa_camera_pos : packoffset(c0);\n    float4 _653_fa_ambient : packoffset(c1);\n    float4 _653_fa_base_color : packoffset(c2);\n    float4 _653_fa_emissive : packoffset(c3);\n    float4 _653_fa_model_emissive : packoffset(c4);\n    float4 _653_fa_pbr : packoffset(c5);\n    float4 _653_fa_maps : packoffset(c6);\n    float4 _653_fa_fog : packoffset(c7);\n    float4 _653_fa_fog_b : packoffset(c8);\n    float4 _653_fa_fog_c : packoffset(c9);\n    float4 _653_fa_counts : packoffset(c10);\n    float4 _653_fa_env_sky : packoffset(c11);\n    float4 _653_fa_env_horizon : packoffset(c12);\n    float4 _653_fa_time : packoffset(c13);\n    float4 _653_fa_cl_vpx : packoffset(c14);\n    float4 _653_fa_cl_vpy : packoffset(c15);\n    float4 _653_fa_cl_vpw : packoffset(c16);\n    float4 _653_fa_cl_fwd : packoffset(c17);\n    float4 _653_fa_cl_grid : packoffset(c18);\n    float4 _653_fa_cl_info : packoffset(c19);\n    float4 _653_fa_layers_a : packoffset(c20);\n    float4 _653_fa_layers_b : packoffset(c21);\n    float4 _653_fa_layers_c : packoffset(c22);\n    float4 _653_fa_layers_d : packoffset(c23);\n    float4 _653_fa_ct_a : packoffset(c24);\n    float4 _653_fa_ct_b : packoffset(c25);\n    float4 _653_fa_ct_vpx : packoffset(c26);\n    float4 _653_fa_ct_vpy : packoffset(c27);\n    float4 _653_fa_ct_vpw : packoffset(c28);\n    float4 _653_fa_ct_fwd : packoffset(c29);\n    float4 _653_fa_tr_a : packoffset(c30);\n    float4 _653_fa_tr_b : packoffset(c31);\n    float4 _653_fa_probe_sh[9] : packoffset(c32);\n    float4 _653_fa_atlas : packoffset(c41);\n    float4 _653_fa_rpa_tile : packoffset(c42);\n    float4 _653_fa_rpa_pos : packoffset(c43);\n    float4 _653_fa_rpa_bx : packoffset(c44);\n    float4 _653_fa_rpa_by : packoffset(c45);\n    float4 _653_fa_rpa_bz : packoffset(c46);\n    float4 _653_fa_rpb_tile : packoffset(c47);\n    float4 _653_fa_rpb_pos : packoffset(c48);\n    float4 _653_fa_rpb_bx : packoffset(c49);\n    float4 _653_fa_rpb_by : packoffset(c50);\n    float4 _653_fa_rpb_bz : packoffset(c51);\n    float4 _653_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2315_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2315_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2315_fa_shadow_info[4] : packoffset(c20);\n    float4 _2315_fa_shadow_split : packoffset(c24);\n    float4 _2315_fa_shadow_cfg : packoffset(c25);\n    float4 _2315_fa_shadow_bias : packoffset(c26);\n    float4 _2315_fa_shadow_eye : packoffset(c27);\n    float4 _2315_fa_shadow_fwd : packoffset(c28);\n    float4 _2315_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8022_alphaCutoff : packoffset(c0);\n    float _8022_fa_pad0 : packoffset(c0.y);\n    float _8022_fa_pad1 : packoffset(c0.z);\n    float _8022_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1591 = _653_fa_cl_info.x < 0.0f;\n    bool _1598;\n    if (!_1591)\n    {\n        _1598 = _653_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1598 = _1591;\n    }\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = _653_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    bool _1613;\n    if (!_1606)\n    {\n        _1613 = _653_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1613 = _1606;\n    }\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = _653_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    if (_1620)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1630 = float4(world_pos, 1.0f);\n    float _1636 = dot(_653_fa_cl_vpw, _1630);\n    if (!(_1636 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1658 = float2(dot(_653_fa_cl_vpx, _1630), dot(_653_fa_cl_vpy, _1630)) / _1636.xx;\n    int _1662 = int(_653_fa_cl_grid.x);\n    int _1666 = int(_653_fa_cl_grid.y);\n    int param = (int(_653_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_653_fa_cl_fwd.xyz, world_pos) + _653_fa_cl_fwd.w, _653_fa_cl_grid.w) / _653_fa_cl_grid.w) * _653_fa_cl_grid.z)), 0, int(_653_fa_cl_info.y) - 1) * _1666) + clamp(int(floor(((_1658.y * 0.5f) + 0.5f) * _653_fa_cl_grid.y)), 0, _1666 - 1)) * _1662)) + clamp(int(floor(((_1658.x * 0.5f) + 0.5f) * _653_fa_cl_grid.x)), 0, _1662 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1742 = fa_cluster_texel(param);\n    return int2(int(_1742.x), int(_1742.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_653_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5828 = fa_cluster_lookup(param);\n    fa_cl_slot = _5828.x;\n    fa_cl_local = _5828.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6972 = fa_linear_to_srgb(param);\n        c = _6972;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6980 = fa_srgb_to_linear(param_1);\n            c = _6980;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _535;\n    if (i.front_facing)\n    {\n        _535 = i.world_normal;\n    }\n    else\n    {\n        _535 = -i.world_normal;\n    }\n    float3 _559 = normalize(i.world_tangent.xyz - (_535 * dot(_535, i.world_tangent.xyz)));\n    float3 _586 = normalize(((_559 * m.x) + ((cross(_535, _559) * i.world_tangent.w) * m.y)) + (_535 * m.z));\n    float3 _589;\n    if (i.front_facing)\n    {\n        _589 = _586;\n    }\n    else\n    {\n        _589 = -_586;\n    }\n    return _589;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _653_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7011 = fa_tex_fix(param_2, param_3);\n    float4 _9280 = base_t;\n    _9280.x = _7011.x;\n    _9280.y = _7011.y;\n    _9280.z = _7011.z;\n    base_t = _9280;\n    float4 _7025 = (_9280 * _653_fa_base_color) * i.vertex_color;\n    float3 _9064 = i.world_normal;\n    if (_653_fa_maps.z > 0.5f)\n    {\n        float param_4 = _653_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7057 = fa_tex_fix(param_6, param_7);\n        float3 _7060 = (_7057 * 2.0f) - 1.0f.xxx;\n        float2 _7065 = _7060.xy * _653_fa_maps.x;\n        float3 _9288 = _7060;\n        _9288.x = _7065.x;\n        _9288.y = _7065.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9288;\n        _9064 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _653_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7093 = fa_tex_fix(param_12, param_13);\n    float4 _9291 = mrt;\n    _9291.x = _7093.x;\n    _9291.y = _7093.y;\n    _9291.z = _7093.z;\n    mrt = _9291;\n    float4 _7121 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _653_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7121.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7132 = fa_tex_fix(param_16, param_17);\n    float param_18 = _653_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7162 = fa_tex_fix(param_20, param_21);\n    float _9069 = _653_fa_layers_a.x;\n    float _9070 = _653_fa_layers_a.y;\n    float _9073 = _653_fa_layers_a.z;\n    float _9072 = _653_fa_layers_b.w;\n    float _9075 = _653_fa_layers_c.x;\n    if (_653_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_653_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9069 *= _7132.y;\n            _9070 *= _7132.z;\n            _9072 *= _7121.w;\n        }\n        if (_653_fa_layers_c.z > 1.5f)\n        {\n            _9073 *= mrt.x;\n            _9075 *= mrt.w;\n        }\n    }\n    Surface _9102 = { _7025.xyz, _7025.w, _9064, clamp(_653_fa_pbr.x * _7093.z, 0.0f, 1.0f), clamp(_653_fa_pbr.y * _7093.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_653_fa_maps.y * (_7132.x - 1.0f)), _653_fa_emissive.xyz + (_653_fa_model_emissive.xyz * _7162), _9069, _9070, _653_fa_layers_b.xyz, _9072, _9073, _653_fa_layers_a.w, _9075, _653_fa_layers_c.y, _653_fa_layers_d.xyz, _653_fa_tr_a.x, _653_fa_tr_a.y, _653_fa_tr_b.xyz, _653_fa_tr_a.z };\n    return _9102;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1822 = rect.zw - rect.xy;\n    float2 _1826 = _1822 * atlas;\n    float2 _1830 = ddx * _1826;\n    float2 _1834 = ddy * _1826;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1822), clamp(0.5f * log2(max(max(dot(_1830, _1830), dot(_1834, _1834)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1867 = _653_fa_counts.y < 0.5f;\n    bool _1874;\n    if (!_1867)\n    {\n        _1874 = _653_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1874 = _1867;\n    }\n    if (_1874)\n    {\n        return;\n    }\n    float3 _1880 = ddx(world_pos);\n    float3 _1883 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1887 = fa_cluster_texel(param);\n    int _1891 = int(_1887.w);\n    if (_1891 < 1)\n    {\n        return;\n    }\n    int _1901 = int(_653_fa_counts.y + 0.5f);\n    int param_1 = _1901;\n    float4 _1905 = fa_light_texel(param_1);\n    float2 _1908 = _1905.yz;\n    int _1912 = int(_1905.w);\n    int param_2 = _1901 + 1;\n    float4 _1917 = fa_light_texel(param_2);\n    float _1918 = _1917.x;\n    int _1924 = int(_653_fa_counts.w + 0.5f) - 1;\n    int _1928 = int(_1887.z);\n    float3 _2193;\n    for (int k = 0; k < _1891; k++)\n    {\n        int _1941 = _1928 + k;\n        int param_3 = _1912 + (_1941 >> 2);\n        int _1958 = (_1901 + 2) + (int(fa_light_texel(param_3)[_1941 & 3]) * 7);\n        int param_4 = _1958 + 6;\n        float4 _1963 = fa_light_texel(param_4);\n        if (((int(_1963.w + 0.5f) >> _1924) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1958;\n        float4 _1978 = fa_light_texel(param_5);\n        int param_6 = _1958 + 1;\n        float4 _1983 = fa_light_texel(param_6);\n        int param_7 = _1958 + 2;\n        float4 _1988 = fa_light_texel(param_7);\n        float3 _1991 = _1978.xyz;\n        float _1996 = dot(_1991, world_pos) + _1978.w;\n        float3 _1998 = _1983.xyz;\n        float _2003 = dot(_1998, world_pos) + _1983.w;\n        float3 _2005 = _1988.xyz;\n        float _2010 = dot(_2005, world_pos) + _1988.w;\n        bool _2015 = abs(_1996) > 0.5f;\n        bool _2023;\n        if (!_2015)\n        {\n            _2023 = abs(_2003) > 0.5f;\n        }\n        else\n        {\n            _2023 = _2015;\n        }\n        bool _2031;\n        if (!_2023)\n        {\n            _2031 = abs(_2010) > 0.5f;\n        }\n        else\n        {\n            _2031 = _2023;\n        }\n        if (_2031)\n        {\n            continue;\n        }\n        float _2046 = clamp(dot(geo_normal, normalize(_2005)) * _1963.z, 0.0f, 1.0f);\n        if (_2046 <= 0.0f)\n        {\n            continue;\n        }\n        float _2066 = (clamp((0.5f - abs(_2010)) * 10.0f, 0.0f, 1.0f) * _2046) * _1963.x;\n        float2 _2074 = float2(_1996 + 0.5f, 0.5f - _2003);\n        float2 _2084 = float2(dot(_1991, _1880), dot(_1998, _1880));\n        float2 _2094 = float2(dot(_1991, _1883), dot(_1998, _1883));\n        int param_8 = _1958 + 5;\n        float4 _2099 = fa_light_texel(param_8);\n        int param_9 = _1958 + 3;\n        float4 _2104 = fa_light_texel(param_9);\n        int param_10 = _1958 + 4;\n        float4 _2109 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2099.xyz;\n        bool _2119 = _2104.z > _2104.x;\n        if (_2119)\n        {\n            float4 param_11 = _2104;\n            float2 param_12 = _2074;\n            float2 param_13 = _1908;\n            float2 param_14 = _2084;\n            float2 param_15 = _2094;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1918 > 0.5f) && (_1918 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2145 = fa_dc_to_linear(param_16);\n                float4 _9152 = tx;\n                _9152.x = _2145.x;\n                _9152.y = _2145.y;\n                _9152.z = _2145.z;\n                tx = _9152;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2066 * tex_a) * _2099.w, 0.0f, 1.0f).xxx);\n        if (_2109.z > _2109.x)\n        {\n            float4 param_17 = _2109;\n            float2 param_18 = _2074;\n            float2 param_19 = _1908;\n            float2 param_20 = _2084;\n            float2 param_21 = _2094;\n            float4 _2189 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1918 > 1.5f)\n            {\n                float3 param_22 = _2189.xyz;\n                float3 _2199 = fa_dc_to_srgb(param_22);\n                _2193 = _2199;\n            }\n            else\n            {\n                _2193 = _2189.xyz;\n            }\n            float3 _2208 = (_2193 * 2.0f) - 1.0f.xxx;\n            float2 _2213 = _2208.xy * _1963.y;\n            float3 _2235 = (normalize(_1991) * _2213.x) + (normalize(_1998) * _2213.y);\n            float3 _2238 = normalize(normal);\n            normal = normalize(lerp(_2238, normalize((_2238 * max(_2208.z, 0.0500000007450580596923828125f)) + (_2235 - (_2238 * dot(_2238, _2235)))), clamp(_2066 * (_2119 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4278 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4286 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4289 = int(_4278);\n    int _4292 = int(_4286);\n    float _4302 = _4286 - float(_4292);\n    int _4357 = (_4289 * 9) + _4292;\n    int _4377 = ((_4289 + 1) * 9) + _4292;\n    return lerp(lerp(_4353[_4357], _4353[_4357 + 1], _4302), lerp(_4353[_4377], _4353[_4377 + 1], _4302), _4278 - float(_4289));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _8987 = false;\n    float _8988 = 1.0f;\n    float _8989 = 1.0f;\n    float _8990 = 1.0f;\n    float _8991 = 0.0f;\n    float _8992 = 0.0f;\n    float _8993 = 0.0f;\n    float _8994 = 0.0f;\n    float _8996 = 1.0f;\n    bool _8997 = false;\n    float3 _8998 = 0.0f.xxx;\n    float _8999 = 1.0f;\n    float _9000 = 1.0f;\n    float _9001 = 1.0f;\n    float _9002 = 0.0f;\n    float _9003 = 0.0f;\n    float3 _9004 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9005 = float3(0.0f, 0.0f, 1.0f);\n    float _9006 = 1.0f;\n    float _9007 = 1.0f;\n    float _4428 = clamp(s.specular, 0.0f, 1.0f);\n    float _4432 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4437 = (_4428 != 1.0f) || (_4432 != 1.5f);\n    bool _4446;\n    if (!_4437)\n    {\n        _4446 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4446 = _4437;\n    }\n    if (_4446)\n    {\n        float _4454 = (_4432 - 1.0f) / (_4432 + 1.0f);\n        f0 = lerp(min((_4454 * _4454).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4428, s.albedo, metallic.xxx);\n        _8988 = lerp(_4428, 1.0f, metallic);\n        _8987 = true;\n    }\n    float _4481 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4481 > 0.0f)\n    {\n        float _4489 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _8991 = _4481;\n        _8992 = _4489;\n        float _4496 = _4489 * _4489;\n        _8993 = _4496;\n        _8994 = _4496 * _4496;\n        float _4508 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _8996 = _4508;\n        _8989 = 1.0f - (_4481 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4508, 0.0f, 1.0f), 5.0f))));\n        _8987 = true;\n    }\n    float3 _4527 = max(s.sheen_color, 0.0f.xxx);\n    float _4536 = max(_4527.x, max(_4527.y, _4527.z));\n    if (_4536 > 0.0f)\n    {\n        float _4544 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _8997 = true;\n        _8998 = _4527;\n        _8999 = _4544;\n        _9000 = _4544 * _4544;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4544;\n        float _4561 = fa_sheen_albedo(param, param_1);\n        _9002 = _4561;\n        _9001 = 1.0f - min(_4536 * _4561, 1.0f);\n        _8987 = true;\n    }\n    _8990 = _8989 * _9001;\n    float _4580 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4580 != 0.0f)\n    {\n        float3 _4595 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4595;\n        if (dot(_4595, _4595) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4607 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4607.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4607.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4607.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4611 = t;\n        float3 _4612 = normalize(_4611);\n        t = _4612;\n        float3 _4637 = normalize((_4612 * cos(s.anisotropy_rotation)) + ((cross(n, _4612) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9004 = _4637;\n        _9005 = cross(n, _4637);\n        float _4647 = roughness * roughness;\n        float _4653 = lerp(_4647, 1.0f, _4580 * _4580);\n        bool _4655 = _4580 > 0.0f;\n        _9006 = _4655 ? _4653 : _4647;\n        _9007 = _4655 ? _4647 : _4653;\n        _9003 = _4580;\n        _8987 = true;\n    }\n    FaLayers _9029 = { _8987, _8988, _8989, _8990, _8991, _8992, _8993, _8994, i.world_normal, _8996, _8997, _8998, _8999, _9000, _9001, _9002, _9003, _9004, _9005, _9006, _9007 };\n    return _9029;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3505_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3505_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_653_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3446 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3446;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4059 = (1.0f - _653_fa_rpa_tile.w) - _653_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4064 = _653_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4059 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4064)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _653_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4059;\n            }\n        }\n        else\n        {\n            amb = _653_fa_ambient.xyz * _4059;\n        }\n    }\n    bool _4115 = _653_fa_rpa_tile.w > 0.0f;\n    if (_4115)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _653_fa_rpa_tile.xy;\n            float param_4 = _653_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _653_fa_rpa_tile.w);\n        }\n    }\n    bool _4146 = _653_fa_rpb_tile.w > 0.0f;\n    if (_4146)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _653_fa_rpb_tile.xy;\n            float param_7 = _653_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _653_fa_rpb_tile.w);\n        }\n    }\n    if ((_4064 || _4115) || _4146)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3466 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3469 = _3466.x;\n    float _3471 = _3466.z;\n    float2 e = float2(_3469, _3471);\n    if (_3466.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3471)) * ((_3469 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3469)) * ((_3471 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7272 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7277 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7282 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7287 = fa_light_texel(param_3);\n    bool _7290 = _7287.z < 0.5f;\n    bool _7298;\n    if (!_7290)\n    {\n        _7298 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7298 = _7290;\n    }\n    if (_7298)\n    {\n        return 0.0f.xxx;\n    }\n    float _7305 = max(_7272.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7308 = _7277.xyz;\n    float3 _7312 = _7272.xyz;\n    float3 _7316 = (fa_world_pos - _7312) / _7305.xxx;\n    float3 _7325 = min(_7316 + 0.5f.xxx, (_7308 - 0.5f.xxx) - _7316);\n    float _7334 = min(_7325.x, min(_7325.y, _7325.z));\n    if (!(_7334 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7349 = _7308 - 1.0f.xxx;\n    float3 _7350 = clamp(_7316, 0.0f.xxx, _7349);\n    float3 _7358 = min(floor(_7350), max(_7308 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7362 = _7350 - _7358;\n    float3 _7373 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7305));\n    int _7378 = int(_7282.y + 0.5f);\n    float _7383 = 0.3257350027561187744140625f * n.y;\n    float _7387 = 0.3257350027561187744140625f * n.z;\n    float _7391 = 0.3257350027561187744140625f * n.x;\n    float _7398 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _7405 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _7414 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _7421 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _7434 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _7441 = 8 + int(_7287.w);\n    float _7468;\n    float _7481;\n    float _7495;\n    for (int k = 0; k < _7441; k++)\n    {\n        float _7454 = float(k & 1);\n        float _7458 = float((k >> 1) & 1);\n        float _7462 = float((k >> 2) & 1);\n        if (_7454 > 0.5f)\n        {\n            _7468 = _7362.x;\n        }\n        else\n        {\n            _7468 = 1.0f - _7362.x;\n        }\n        if (_7458 > 0.5f)\n        {\n            _7481 = _7362.y;\n        }\n        else\n        {\n            _7481 = 1.0f - _7362.y;\n        }\n        if (_7462 > 0.5f)\n        {\n            _7495 = _7362.z;\n        }\n        else\n        {\n            _7495 = 1.0f - _7362.z;\n        }\n        float _7505 = (_7468 * _7481) * _7495;\n        if (!(_7505 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7518 = min(_7358 + float3(_7454, _7458, _7462), _7349);\n        int _7538 = int(((_7282.x + _7518.x) + (_7277.x * (_7518.y + (_7277.y * _7518.z)))) + 0.5f);\n        float2 _7553 = float2(float(_7538 % _7378) * 10.0f, 1024.0f + (float(_7538 / _7378) * 11.0f));\n        float2 param_4 = _7553 + float2(9.5f, 10.5f);\n        float4 _7561 = fa_gi_fetch(param_4);\n        bool _7564 = _7561.y < 0.5f;\n        bool _7573;\n        if (!_7564)\n        {\n            _7573 = _7561.x > _7287.y;\n        }\n        else\n        {\n            _7573 = _7564;\n        }\n        if (_7573)\n        {\n            continue;\n        }\n        float3 _7585 = _7373 - (_7312 + (_7518 * _7305));\n        float _7588 = length(_7585);\n        float3 _7594 = _7585 / max(_7588, 9.9999997473787516355514526367188e-05f).xxx;\n        float _7604 = max(9.9999997473787516355514526367188e-05f, (dot(-_7594, n) + 1.0f) * 0.5f);\n        float w = _7505 * (_7604 * _7604);\n        float3 param_5 = _7594;\n        float2 param_6 = (_7553 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _7623 = fa_gi_fetch(param_6);\n        float _7630 = _7588 / max(_7282.z, 9.9999997473787516355514526367188e-05f);\n        float _7633 = _7623.x;\n        if (_7630 > _7633)\n        {\n            float _7646 = max(_7623.y - (_7633 * _7633), 0.0f);\n            float _7651 = _7630 - _7633;\n            float _7660 = _7646 / max(_7646 + (_7651 * _7651), 9.9999999600419720025001879548654e-13f);\n            w *= ((_7660 * _7660) * _7660);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _7553 + float2(0.5f, 10.5f);\n        float2 param_8 = _7553 + float2(1.5f, 10.5f);\n        float2 param_9 = _7553 + float2(2.5f, 10.5f);\n        float2 param_10 = _7553 + float2(3.5f, 10.5f);\n        float2 param_11 = _7553 + float2(4.5f, 10.5f);\n        float2 param_12 = _7553 + float2(5.5f, 10.5f);\n        float2 param_13 = _7553 + float2(6.5f, 10.5f);\n        float2 param_14 = _7553 + float2(7.5f, 10.5f);\n        float2 param_15 = _7553 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _7383)) + (fa_gi_fetch(param_9).xyz * _7387)) + (fa_gi_fetch(param_10).xyz * _7391)) + (fa_gi_fetch(param_11).xyz * _7398)) + (fa_gi_fetch(param_12).xyz * _7405)) + (fa_gi_fetch(param_13).xyz * _7414)) + (fa_gi_fetch(param_14).xyz * _7421)) + (fa_gi_fetch(param_15).xyz * _7434)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7334 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _7785;\n    if (_653_fa_gi.z > 0.5f)\n    {\n        _7785 = _7287.x;\n    }\n    else\n    {\n        _7785 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7282.w * _7785);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _7809 = normalize(_653_fa_camera_pos.xyz - fa_world_pos);\n    int _7814 = int(_653_fa_gi.x + 0.5f);\n    int _7819 = int(_653_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _7819) && (k < 8); k++)\n    {\n        int param = _7814 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _7809;\n        float3 _7844 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7849 = param_3 * left;\n        acc += (_7844 * _7849);\n        left -= _7849;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_653_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _7878 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7878;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_653_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _653_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_653_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_653_fa_cl_info.x) + int(_653_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_653_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5798;\n    if (fa_lm.z > 0.5f)\n    {\n        _5798 = 0.0f;\n    }\n    else\n    {\n        _5798 = 1.0f - clamp(_653_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5809 = _5798 < 1.0f;\n    bool _5815;\n    if (_5809)\n    {\n        int param = li;\n        _5815 = fa_light_baked(param);\n    }\n    else\n    {\n        _5815 = _5809;\n    }\n    return _5815 ? _5798 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _721_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _721_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _840 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _853 = (c - (ru * hx)) - p;\n        float3 _859 = ru * (2.0f * hx);\n        float _865 = max(dot(_859, _859), 9.9999999392252902907785028219223e-09f);\n        float _869 = dot(_853, _859);\n        float t = clamp((-_869) / _865, 0.0f, 1.0f);\n        if (_840)\n        {\n            float _884 = dot(r, _859);\n            float _890 = _865 - (_884 * _884);\n            if (abs(_890) > (9.9999997473787516355514526367188e-06f * _865))\n            {\n                t = clamp(((dot(r, _853) * _884) - _869) / _890, 0.0f, 1.0f);\n            }\n        }\n        return (p + _853) + (_859 * t);\n    }\n    float3 q = p;\n    float _922 = dot(r, axis);\n    bool _930;\n    if (_840)\n    {\n        _930 = abs(_922) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _930 = _840;\n    }\n    if (_930)\n    {\n        float _940 = dot(c - p, axis) / _922;\n        if (_940 > 0.0f)\n        {\n            q = p + (r * _940);\n        }\n    }\n    float3 _953 = q - c;\n    float2 xy = float2(dot(_953, ru), dot(_953, uu));\n    if (shape > 0.5f)\n    {\n        float _968 = length(xy);\n        if (_968 > hx)\n        {\n            xy *= (hx / _968);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _601 = abs(d);\n    float _603 = _601.x;\n    float _605 = _601.y;\n    bool _606 = _603 >= _605;\n    bool _614;\n    if (_606)\n    {\n        _614 = _603 >= _601.z;\n    }\n    else\n    {\n        _614 = _606;\n    }\n    int _615;\n    if (_614)\n    {\n        _615 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _630;\n        if (_605 >= _601.z)\n        {\n            _630 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _630 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _615 = _630;\n    }\n    return _615;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _760 = dot(d, right);\n    float _764 = dot(d, up);\n    float _775;\n    if (((_760 * _760) + (_764 * _764)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _775 = atan2(_764, _760) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _775 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_775 - floor(_775)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1006 = fa_light_base(param);\n    bool _1010 = _653_fa_ambient.w > 4.5f;\n    int param_1 = _1006;\n    float4 _1014 = fa_light_texel(param_1);\n    int param_2 = _1006 + 1;\n    float4 _1019 = fa_light_texel(param_2);\n    float _1022 = _1019.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1034 = _1010 && (_1022 > 2.5f);\n    fa_light_is_area = _1034;\n    bool _1036 = _1022 < 0.5f;\n    float3 l;\n    if (_1036)\n    {\n        l = normalize(_1014.xyz);\n        if (_1010)\n        {\n            int param_3 = _1006 + 6;\n            float4 _1050 = fa_light_texel(param_3);\n            if (_1050.z > 0.5f)\n            {\n                int param_4 = _1006 + 4;\n                float4 _1060 = fa_light_texel(param_4);\n                int param_5 = _1006 + 5;\n                float4 _1065 = fa_light_texel(param_5);\n                float2 param_6 = _1050.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1060.xyz) * _1060.w, (-dot(world_pos, _1065.xyz)) * _1065.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1095 = _1014.xyz;\n        float3 _1097 = _1095 - world_pos;\n        float3 to_light = _1097;\n        float _1100 = length(_1097);\n        float reach = _1100;\n        bool front = true;\n        if (_1034)\n        {\n            int param_8 = _1006 + 7;\n            reach = max(_1100 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1006 + 4;\n            float4 _1124 = fa_light_texel(param_9);\n            int param_10 = _1006 + 5;\n            float4 _1129 = fa_light_texel(param_10);\n            int param_11 = _1006 + 6;\n            float4 _1134 = fa_light_texel(param_11);\n            float _1135 = _1134.w;\n            int param_12 = _1006 + 2;\n            float3 _1142 = normalize(fa_light_texel(param_12).xyz);\n            bool _1144 = _1135 > 1.5f;\n            bool _1152;\n            if (!_1144)\n            {\n                _1152 = dot(_1142, to_light) < 0.0f;\n            }\n            else\n            {\n                _1152 = _1144;\n            }\n            front = _1152;\n            float3 r = 0.0f.xxx;\n            float3 _1161 = _653_fa_camera_pos.xyz - world_pos;\n            bool _1165 = dot(n, n) > 0.5f;\n            bool _1173;\n            if (_1165)\n            {\n                _1173 = dot(_1161, _1161) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1173 = _1165;\n            }\n            if (_1173)\n            {\n                r = reflect(-normalize(_1161), normalize(n));\n            }\n            float3 param_13 = _1095;\n            float3 param_14 = _1142;\n            float3 param_15 = _1124.xyz;\n            float3 param_16 = _1129.xyz;\n            float param_17 = _1124.w;\n            float param_18 = _1129.w;\n            float param_19 = _1135;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1209 = length(to_light);\n        dist = _1209;\n        l = to_light / max(_1209, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1223 = reach / max(_1014.w, 0.001000000047497451305389404296875f);\n        float _1229 = clamp(1.0f - (_1223 * _1223), 0.0f, 1.0f);\n        float _1231;\n        if (front)\n        {\n            _1231 = _1229 * _1229;\n        }\n        else\n        {\n            _1231 = 0.0f;\n        }\n        atten = _1231;\n        bool _1242 = _1022 < 2.5f;\n        if ((_1022 > 1.5f) && _1242)\n        {\n            int param_22 = _1006 + 2;\n            float4 _1250 = fa_light_texel(param_22);\n            float _1260 = _1250.w;\n            int param_23 = _1006 + 3;\n            float4 _1265 = fa_light_texel(param_23);\n            float _1266 = _1265.x;\n            float cos_inner = _1266;\n            if (_1266 > 1.5f)\n            {\n                cos_inner = lerp(_1260, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1260, cos_inner, dot(-l, normalize(_1250.xyz)));\n        }\n        if (_1010 && (_1022 < 1.5f))\n        {\n            int param_24 = _1006 + 6;\n            float4 _1290 = fa_light_texel(param_24);\n            if (_1290.z > 0.5f)\n            {\n                float3 _1298 = -to_light;\n                int param_25 = _1006 + 4;\n                int param_26 = _1006 + 5;\n                float3 _1312 = fa_light_texel(param_25).xyz;\n                float3 _1316 = fa_light_texel(param_26).xyz;\n                float3 _1325 = float3(dot(_1298, _1312), dot(_1298, _1316), dot(_1298, cross(_1312, _1316)));\n                float3 param_27 = _1325;\n                int _1329 = fa_cube_face(param_27);\n                int param_28 = _1329;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1356 = float2(dot(_1325, cross(param_29, param_30)), dot(_1325, param_30)) / max(dot(_1325, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1360 = _1329 / 3;\n                float2 param_31 = _1290.xy + (float2(float(_1329 - (_1360 * 3)), float(_1360)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1356.x), 0.5f - (0.5f * _1356.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1006 + 7;\n            float4 _1390 = fa_light_texel(param_33);\n            if (_1390.z > 0.5f)\n            {\n                int param_34 = _1006 + 2;\n                int param_35 = _1006 + 4;\n                int param_36 = _1006 + 5;\n                float2 param_37 = _1390.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1010 && _1242)\n            {\n                int param_42 = _1006 + 6;\n                float4 _1437 = fa_light_texel(param_42);\n                int param_43 = _1006 + 7;\n                float4 _1442 = fa_light_texel(param_43);\n                bool _1445 = _1437.z > 0.5f;\n                bool _1452;\n                if (!_1445)\n                {\n                    _1452 = _1442.z > 0.5f;\n                }\n                else\n                {\n                    _1452 = _1445;\n                }\n                if (_1452)\n                {\n                    int param_44 = _1006 + 2;\n                    float4 _1459 = fa_light_texel(param_44);\n                    float3 _1463 = normalize(_1459.xyz);\n                    int param_45 = _1006 + 4;\n                    float4 _1468 = fa_light_texel(param_45);\n                    int param_46 = _1006 + 5;\n                    float4 _1473 = fa_light_texel(param_46);\n                    if (_1445)\n                    {\n                        float3 _1481 = -to_light;\n                        float _1488 = _1459.w;\n                        float _1504 = 0.5f / max(dot(_1481, _1463) * (sqrt(max(1.0f - (_1488 * _1488), 0.0f)) / max(_1488, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1437.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1481, _1468.xyz) * _1504), 0.5f - (dot(_1481, _1473.xyz) * _1504));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1442.z > 0.5f)\n                    {\n                        float2 param_49 = _1442.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1463;\n                        float3 param_52 = _1468.xyz;\n                        float3 param_53 = _1473.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _8975 = _1019.xyz * atten;\n    if (_1010)\n    {\n        _8975 *= fa_light_tint;\n    }\n    int _1573;\n    if (_1036)\n    {\n        _1573 = 0;\n    }\n    else\n    {\n        _1573 = ((_1022 > 1.5f) && (_1022 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _8986 = { l, _8975, atten, 1.0f, dist, _1573 };\n    return _8986;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2305;\n    if (i == 0)\n    {\n        _2305 = _2315_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2321;\n        if (i == 1)\n        {\n            _2321 = _2315_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2329;\n            if (i == 2)\n            {\n                _2329 = _2315_fa_shadow_split.z;\n            }\n            else\n            {\n                _2329 = _2315_fa_shadow_split.w;\n            }\n            _2321 = _2329;\n        }\n        _2305 = _2321;\n    }\n    return _2305;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2362 = fa_shadow_depth(param, param_1);\n    float _2366;\n    if (conv.x < 0.5f)\n    {\n        _2366 = _2362;\n    }\n    else\n    {\n        _2366 = (conv.y * conv.z) / (conv.z - (_2362 * (conv.z - conv.y)));\n    }\n    return _2366;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2412 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2418 = float2(cos(_2412), sin(_2412));\n    float2 dir = _2418;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2427;\n        if (k < 0.0f)\n        {\n            _2427 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2427 = k;\n        }\n        float _2446 = clamp((_2427 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2465 = sqrt((float(i) + 0.5f) * 0.0625f) * _2446;\n            float2 param_3 = uv + (dir * (_2315_fa_shadow_bias.zw * _2465));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2479 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2479 < (zr - (_2465 * plane)))\n            {\n                sum += _2479;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2507 = sum / cnt;\n        float _2517;\n        if (k < 0.0f)\n        {\n            _2517 = (-k) / max(_2507, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2517 = k;\n        }\n        radius = clamp(((max(zr - _2507, 0.0f) * unit) * _2517) / texel_m, 1.5f, 16.0f);\n        dir = _2418;\n    }\n    float lit = 0.0f;\n    int _2543 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2543; i_1++)\n    {\n        float _2562 = sqrt((float(i_1) + 0.5f) / float(_2543)) * radius;\n        float2 param_7 = uv + (dir * (_2315_fa_shadow_bias.zw * _2562));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2562 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2543);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2608 = max(_2315_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2613 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2619 = sqrt(1.0f - (_2613 * _2613));\n    float _2627 = min(_2619 / max(_2613, 0.20000000298023223876953125f), 4.0f);\n    float _2632;\n    if (_2315_fa_shadow_bias.y > 0.0f)\n    {\n        _2632 = _2315_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2632 = 1.5f * _2315_fa_shadow_info[ci].x;\n    }\n    float4 _2657 = mul(float4(world + (n * (_2632 * _2619)), 1.0f), _2315_fa_shadow_mat[ci]);\n    float _2664 = _2657.x;\n    bool _2667 = _2664 < _2315_fa_shadow_rect[ci].x;\n    bool _2676;\n    if (!_2667)\n    {\n        _2676 = _2664 > _2315_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2676 = _2667;\n    }\n    bool _2685;\n    if (!_2676)\n    {\n        _2685 = _2657.y < _2315_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2685 = _2676;\n    }\n    bool _2694;\n    if (!_2685)\n    {\n        _2694 = _2657.y > _2315_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2694 = _2685;\n    }\n    bool _2701;\n    if (!_2694)\n    {\n        _2701 = _2657.z > 1.0f;\n    }\n    else\n    {\n        _2701 = _2694;\n    }\n    if (_2701)\n    {\n        return -1.0f;\n    }\n    float _2709;\n    if (_2315_fa_shadow_bias.x > 0.0f)\n    {\n        _2709 = _2315_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2709 = 1.5f * _2315_fa_shadow_info[ci].x;\n    }\n    float2 param = _2657.xy;\n    float4 param_1 = _2315_fa_shadow_rect[ci];\n    float param_2 = _2657.z - ((_2709 * (1.0f + (0.5f * _2627))) / _2608);\n    float param_3 = _2315_fa_shadow_info[ci].x;\n    float param_4 = _2608;\n    float param_5 = _2608 * 0.25f;\n    float param_6 = ((_2315_fa_shadow_info[ci].x * min(_2627, 3.0f)) * 0.5f) / _2608;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2315_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2315_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_653_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3087 = int(_2315_fa_shadow_cfg.x + 0.5f);\n    if (_3087 < 1)\n    {\n        return 1.0f;\n    }\n    float _3102 = dot(world - _2315_fa_shadow_eye.xyz, _2315_fa_shadow_fwd.xyz);\n    int param = _3087 - 1;\n    if (_3102 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3114 = _3087 > 1;\n    bool _3121;\n    if (_3114)\n    {\n        _3121 = _3102 > _2315_fa_shadow_split.x;\n    }\n    else\n    {\n        _3121 = _3114;\n    }\n    if (_3121)\n    {\n        ci = 1;\n    }\n    bool _3125 = _3087 > 2;\n    bool _3132;\n    if (_3125)\n    {\n        _3132 = _3102 > _2315_fa_shadow_split.y;\n    }\n    else\n    {\n        _3132 = _3125;\n    }\n    if (_3132)\n    {\n        ci = 2;\n    }\n    bool _3136 = _3087 > 3;\n    bool _3143;\n    if (_3136)\n    {\n        _3143 = _3102 > _2315_fa_shadow_split.z;\n    }\n    else\n    {\n        _3143 = _3136;\n    }\n    if (_3143)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3087)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3169 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3169;\n        if (_3169 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2315_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3194;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3194 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3194 = _2315_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3213 = _2315_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3194, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3224 = clamp((_3102 - (fa_shadow_split_at(param_7) - _3213)) / _3213, 0.0f, 1.0f);\n        if (_3224 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3087)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3245 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3245;\n                if (_3245 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3224);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2767 = _653_fa_pbr.z < 0.5f;\n    bool _2774;\n    if (!_2767)\n    {\n        _2774 = _2315_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2774 = _2767;\n    }\n    if (_2774)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2315_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2787 = fa_light_texel(param);\n    float _2788 = _2787.x;\n    if (_2788 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2797 = int(_2788 + 0.5f);\n    int param_1 = _2797;\n    float4 _2801 = fa_light_texel(param_1);\n    int param_2 = _2797 + 1;\n    float4 _2806 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2809 = _2801.y;\n    if (_2809 > 0.0f)\n    {\n        float _2826 = 1.0f - smoothstep(0.75f * _2809, _2809, length(world - _2315_fa_shadow_eye.xyz));\n        fade = _2826;\n        if (_2826 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2801.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2850 = (_2797 + 2) + (face * 6);\n    int param_4 = _2850;\n    int param_5 = _2850 + 1;\n    int param_6 = _2850 + 3;\n    float4 _2864 = fa_light_texel(param_6);\n    int param_7 = _2850 + 4;\n    float4 _2869 = fa_light_texel(param_7);\n    int param_8 = _2850 + 5;\n    float4 _2874 = fa_light_texel(param_8);\n    float _2886 = _2874.x * max(dot(_2864, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2891 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2914 = clamp(dot(n, _2864.xyz), -1.0f, 1.0f);\n    float _2933 = min(sqrt(1.0f - (_2914 * _2914)) / max(abs(dot(n, world - lpos)) / max(dot(_2864, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2936 = _2806.y;\n    float _2938;\n    if (_2936 > 0.0f)\n    {\n        _2938 = _2936;\n    }\n    else\n    {\n        _2938 = 1.5f * _2886;\n    }\n    float4 _2958 = float4(world + (n * (_2938 * sqrt(1.0f - (_2891 * _2891)))), 1.0f);\n    float _2962 = dot(_2864, _2958);\n    float _2965 = _2874.y;\n    if (_2962 < _2965)\n    {\n        return 1.0f;\n    }\n    float2 _2980 = float2(dot(fa_light_texel(param_4), _2958), dot(fa_light_texel(param_5), _2958)) / _2962.xx;\n    float _2982 = _2980.x;\n    bool _2985 = _2982 < _2869.x;\n    bool _2994;\n    if (!_2985)\n    {\n        _2994 = _2982 > _2869.z;\n    }\n    else\n    {\n        _2994 = _2985;\n    }\n    bool _3003;\n    if (!_2994)\n    {\n        _3003 = _2980.y < _2869.y;\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    bool _3012;\n    if (!_3003)\n    {\n        _3012 = _2980.y > _2869.w;\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        return 1.0f;\n    }\n    float _3018 = _2806.x;\n    float _3020;\n    if (_3018 > 0.0f)\n    {\n        _3020 = _3018;\n    }\n    else\n    {\n        _3020 = 1.5f * _2886;\n    }\n    float2 param_9 = _2980;\n    float4 param_10 = _2869;\n    float param_11 = _2962 - (_3020 * (1.0f + (0.5f * _2933)));\n    float param_12 = _2886;\n    float param_13 = 1.0f;\n    float param_14 = _2874.z * 0.25f;\n    float param_15 = (_2886 * min(_2933, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2965, _2874.z);\n    int param_17 = int(_2801.z + 0.5f);\n    float param_18 = _2801.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5171 = _653_fa_ct_a.x < 0.5f;\n    bool _5178;\n    if (!_5171)\n    {\n        _5178 = _2315_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5178 = _5171;\n    }\n    if (_5178)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2315_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5191 = fa_light_texel(param);\n    float _5192 = _5191.y;\n    float len = _5192;\n    if (_5192 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5204 = length(world - _653_fa_camera_pos.xyz);\n    float _5214 = 1.0f - smoothstep(0.5f * _653_fa_ct_b.x, _653_fa_ct_b.x, _5204);\n    if (_5214 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5220 = len;\n    float _5223 = min(_5220, 0.89999997615814208984375f * dist);\n    len = _5223;\n    float _5228 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5204);\n    float _5233 = _5228 + (0.5f * _5223);\n    float3 _5239 = world + (gn * _5228);\n    float _5241 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5305;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5256 = (float(k) + _5241) * 0.083333335816860198974609375f;\n        float3 _5264 = _5239 + (l * (_5256 * len));\n        float4 _5270 = float4(_5264, 1.0f);\n        float _5276 = dot(_653_fa_ct_vpw, _5270);\n        if (_5276 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5296 = float2(dot(_653_fa_ct_vpx, _5270), dot(_653_fa_ct_vpy, _5270)) / _5276.xx;\n        float _5300 = _5296.x * 0.5f;\n        float _5301 = _5300 + 0.5f;\n        if (_653_fa_ct_a.y > 0.5f)\n        {\n            _5305 = (_5296.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5305 = 0.5f - (_5296.y * 0.5f);\n        }\n        bool _5321 = _5301 < 0.0f;\n        bool _5328;\n        if (!_5321)\n        {\n            _5328 = _5301 >= 1.0f;\n        }\n        else\n        {\n            _5328 = _5321;\n        }\n        bool _5335;\n        if (!_5328)\n        {\n            _5335 = _5305 < 0.0f;\n        }\n        else\n        {\n            _5335 = _5328;\n        }\n        bool _5342;\n        if (!_5335)\n        {\n            _5342 = _5305 >= 1.0f;\n        }\n        else\n        {\n            _5342 = _5335;\n        }\n        if (_5342)\n        {\n            break;\n        }\n        float4 _5369 = fa_screen_tex.Load(int3(clamp(int2(float2(_5301, _5305) * _653_fa_ct_a.zw), int2(0, 0), int2(_653_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5369.w < 0.5f)\n        {\n            continue;\n        }\n        float _5388 = (dot(_653_fa_ct_fwd.xyz, _5264) + _653_fa_ct_fwd.w) - _5369.x;\n        if ((_5388 > _5228) && (_5388 < _5233))\n        {\n            occ = max(occ, (1.0f - (_5256 * _5256)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5301, 0.5f - _5300), min(_5305, 1.0f - _5305))));\n        }\n    }\n    return 1.0f - (occ * _5214);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5854 = fa_baked_keep(param);\n    if (_5854 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9042 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9042;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5880 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9044 = _5880.color;\n    float _9045 = _5880.attenuation;\n    float _9046 = _5880.shadow;\n    bool _5883 = _5880.type == 0;\n    if (_5883 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5880.direction;\n        float _5894 = fa_shadow_factor(param_5, param_6);\n        _9046 = _5894;\n        _9044 *= _5894;\n    }\n    else\n    {\n        bool _5905 = _5880.type != 0;\n        bool _5911;\n        if (_5905)\n        {\n            _5911 = _9045 > 0.0f;\n        }\n        else\n        {\n            _5911 = _5905;\n        }\n        if (_5911)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5880.direction;\n            float _5930 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9046 = _5930;\n            _9044 *= _5930;\n        }\n    }\n    bool _5940 = _653_fa_ct_a.x > 0.5f;\n    bool _5946;\n    if (_5940)\n    {\n        _5946 = _9045 > 0.0f;\n    }\n    else\n    {\n        _5946 = _5940;\n    }\n    if (_5946)\n    {\n        float _5953;\n        if (_5883)\n        {\n            _5953 = 1000000000.0f;\n        }\n        else\n        {\n            _5953 = _5880._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5880.direction;\n        float param_18 = _5953;\n        float _5971 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9046 *= _5971;\n        _9044 *= _5971;\n    }\n    float _5984 = _9045;\n    float _5985 = _5984 * _5854;\n    _9045 = _5985;\n    float3 _5989 = _9044;\n    float3 _5990 = _5989 * _5854;\n    _9044 = _5990;\n    LightSample _9061 = { _5880.direction, _5990, _5985, _9046, _5880._distance, _5880.type };\n    return _9061;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6024 = v - (n * dot(v, n));\n    float3 t = _6024;\n    float _6028 = dot(_6024, _6024);\n    float l2 = _6028;\n    if (_6028 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6038;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6038 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6038 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6038;\n        l2 = dot(_6038, _6038);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6073 = dot(a, a);\n    float _6077 = dot(b, b);\n    if ((_6073 < 1.0000000195414813782625560981111e-24f) || (_6077 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6091 = a * rsqrt(_6073);\n    float3 _6096 = b * rsqrt(_6077);\n    float _6100 = dot(_6091, _6096);\n    float _6103 = abs(_6100);\n    float g = (((((((((((0.0416471660137176513671875f * _6103) - 0.1924748718738555908203125f) * _6103) + 0.4179156124591827392578125f) * _6103) - 0.616057217121124267578125f) * _6103) + 0.777722418308258056640625f) * _6103) - 0.999542415142059326171875f) * _6103) + 1.570791721343994140625f;\n    if (_6100 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6100 * _6100), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6091, _6096) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6160 = a.z > 0.0f;\n    bool _6164 = b.z > 0.0f;\n    if (_6160 && _6164)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6160 != _6164)\n        {\n            float3 _6199 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6199.z = 0.0f;\n            if (_6160)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6199;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6199;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6199;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6199;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6248 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6274 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6300 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6326 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6248;\n    float3 param_1 = _6274;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6274;\n    float3 param_7 = _6300;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6300;\n    float3 param_13 = _6326;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6326;\n    float3 param_19 = _6248;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6475 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6499 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6515 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6475;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6499;\n    float4 param_9 = m;\n    float3 param_10 = _6475;\n    float3 param_11 = _6499;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6515;\n    float4 param_14 = m;\n    float3 param_15 = _6475;\n    float3 param_16 = _6515;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6573 = fa_light_base(param);\n    int param_1 = _6573;\n    int param_2 = _6573 + 1;\n    int param_3 = _6573 + 2;\n    int param_4 = _6573 + 4;\n    float4 _6595 = fa_light_texel(param_4);\n    int param_5 = _6573 + 5;\n    float4 _6600 = fa_light_texel(param_5);\n    int param_6 = _6573 + 6;\n    float4 _6605 = fa_light_texel(param_6);\n    float _6606 = _6605.w;\n    float3 _6611 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6613 = _6606 < 1.5f;\n    bool _6620;\n    if (_6613)\n    {\n        _6620 = dot(normalize(fa_light_texel(param_3).xyz), _6611) >= 0.0f;\n    }\n    else\n    {\n        _6620 = _6613;\n    }\n    if (_6620)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6629 = (_6606 > 0.5f) && _6613;\n    float _6633 = _6629 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6636 = _6595.xyz;\n    float _6638 = _6595.w;\n    float3 _6644 = _6600.xyz;\n    float _6646 = _6600.w;\n    float3 up = _6644 * (_6646 * _6633);\n    float _6652;\n    if (_6629)\n    {\n        _6652 = (3.1415927410125732421875f * _6638) * _6638;\n    }\n    else\n    {\n        _6652 = (4.0f * _6638) * _6646;\n    }\n    if (_6606 > 1.5f)\n    {\n        float3 _6678 = cross(_6636, -_6611);\n        float3 perp = _6678;\n        float _6682 = dot(_6678, _6678);\n        float3 _6685;\n        if (_6682 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6685 = perp * rsqrt(_6682);\n        }\n        else\n        {\n            _6685 = _6644;\n        }\n        perp = _6685;\n        up = _6685 * _6646;\n    }\n    float _6706 = max(_6652, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6716 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6716;\n    float3 param_10 = n;\n    float3 param_11 = _6611;\n    float3 _6724 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6716;\n    float3 param_13 = n;\n    float3 param_14 = _6636 * (_6638 * _6633);\n    float3 _6732 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6716;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6740 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6606;\n    float3 param_20 = _6724;\n    float3 param_21 = _6732;\n    float3 param_22 = _6740;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6759 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6759;\n    float2 param_26 = _6759 + float2(64.0f, 0.0f);\n    float4 _6769 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6606;\n    float3 param_29 = _6724;\n    float3 param_30 = _6732;\n    float3 param_31 = _6740;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6769.x) + ((f90.xxx - f0) * _6769.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6611, _6611)) + _6706) / _6706) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4908 = 1.0f / alpha;\n    return ((2.0f + _4908) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4908)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4943 = max(dot(L.nc, l), 0.0f);\n    float _4949 = max(dot(L.nc, h), 0.0f);\n    float _4958 = ((_4949 * _4949) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4958) * _4958)) * (0.5f / max(lerp((2.0f * _4943) * L.coat_ndv, _4943 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4943)) * _4943;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6837;\n    if (L.sheen_on)\n    {\n        _6837 = L.sheen_scale;\n    }\n    else\n    {\n        _6837 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6837);\n    float3 _6850 = normalize(l + v);\n    int param_10 = li;\n    float3 _6861 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6870 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6850), 0.0f);\n        float param_13 = _6870;\n        float param_14 = ndv;\n        result += ((L.sheen * _6861) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6870)) * _6870) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6850;\n        float param_18 = max(dot(v, _6850), 0.0f);\n        result += (_6861 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4811 = tdh / at;\n    float _4815 = bdh / ab;\n    float _4827 = ((_4811 * _4811) + (_4815 * _4815)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4827) * _4827);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5007 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5086 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5086) * _5086);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5007);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5007));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4210 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4213 = _4210.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4213 * _4213, exp2((-9.27999973297119140625f) * ndv)) * _4213) + _4210.y)) + _4210.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3518;\n    if (lv == 0)\n    {\n        _3518 = 0.0f;\n    }\n    else\n    {\n        _3518 = res + 2.0f;\n    }\n    float _3528;\n    if (lv == 0)\n    {\n        _3528 = 0.0f;\n    }\n    else\n    {\n        _3528 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3518, _3528)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3574;\n    if (res > 64.5f)\n    {\n        _3574 = 5.0f;\n    }\n    else\n    {\n        _3574 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3589 = clamp(rough, 0.0f, 1.0f) * (_3574 - 1.0f);\n    int _3596 = int(min(floor(_3589), _3574 - 2.0f));\n    float _3601 = _3589 - float(_3596);\n    float3 param = d;\n    float2 _3605 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3596;\n    float2 param_4 = _3605;\n    float3 _3615 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3601 < 0.00200000009499490261077880859375f)\n    {\n        return _3615;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3596 + 1;\n    float2 param_8 = _3605;\n    return lerp(_3615, fa_probe_level(param_5, param_6, param_7, param_8), _3601.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3688 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3695 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3702 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3708 = dot(bx.xyz, d);\n    float _3712 = dot(by.xyz, d);\n    float _3716 = dot(bz.xyz, d);\n    float _3722;\n    if (_3708 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3722 = (1.0f - _3688) / _3708;\n    }\n    else\n    {\n        float _3736;\n        if (_3708 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3736 = ((-1.0f) - _3688) / _3708;\n        }\n        else\n        {\n            _3736 = 1000000015047466219876688855040.0f;\n        }\n        _3722 = _3736;\n    }\n    float tx = _3722;\n    float _3753;\n    if (_3712 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3753 = (1.0f - _3695) / _3712;\n    }\n    else\n    {\n        float _3766;\n        if (_3712 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3766 = ((-1.0f) - _3695) / _3712;\n        }\n        else\n        {\n            _3766 = 1000000015047466219876688855040.0f;\n        }\n        _3753 = _3766;\n    }\n    float ty = _3753;\n    float _3782;\n    if (_3716 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3782 = (1.0f - _3702) / _3716;\n    }\n    else\n    {\n        float _3795;\n        if (_3716 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3795 = ((-1.0f) - _3702) / _3716;\n        }\n        else\n        {\n            _3795 = 1000000015047466219876688855040.0f;\n        }\n        _3782 = _3795;\n    }\n    float _3807 = tx;\n    float _3810 = (_3807 > 0.0f) ? _3807 : 1000000015047466219876688855040.0f;\n    tx = _3810;\n    float _3811 = ty;\n    float _3814 = (_3811 > 0.0f) ? _3811 : 1000000015047466219876688855040.0f;\n    ty = _3814;\n    float _3824 = min(_3810, min(_3814, (_3782 > 0.0f) ? _3782 : 1000000015047466219876688855040.0f));\n    if (_3824 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3840 = (fa_world_pos + (d * _3824)) - posw.xyz;\n    float3 _3845;\n    if (dot(_3840, _3840) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3845 = normalize(_3840);\n    }\n    else\n    {\n        _3845 = d;\n    }\n    return _3845;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3891 = (1.0f - _653_fa_rpa_tile.w) - _653_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3891 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_653_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _653_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3919 = rough * rough;\n            float _3950 = 0.60000002384185791015625f * _3919;\n            base = lerp(lerp(_653_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_653_fa_env_horizon.xyz, _653_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3919)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3950, 0.0500000007450580596923828125f + _3950, d.y).xxx), ((_653_fa_env_sky.xyz + _653_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3919 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3891;\n    }\n    if (_653_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _653_fa_rpa_tile;\n        float4 param_5 = _653_fa_rpa_pos;\n        float4 param_6 = _653_fa_rpa_bx;\n        float4 param_7 = _653_fa_rpa_by;\n        float4 param_8 = _653_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4009 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4009 * _653_fa_rpa_tile.w);\n    }\n    if (_653_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _653_fa_rpb_tile;\n        float4 param_12 = _653_fa_rpb_pos;\n        float4 param_13 = _653_fa_rpb_bx;\n        float4 param_14 = _653_fa_rpb_by;\n        float4 param_15 = _653_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4041 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4041 * _653_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4688;\n        if (L.aniso >= 0.0f)\n        {\n            _4688 = L.b;\n        }\n        else\n        {\n            _4688 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4688, v), _4688), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4724 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4724.x) + (L.f90.xxx * _4724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4782 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4782.x) + _4782.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4252 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4252.x) + _4252.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_653_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_653_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5492 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5496 = fa_xm_origin(param_1);\n    float2 _5502 = (uv * _5492) - 0.5f.xx;\n    float2 _5505 = frac(_5502);\n    float2 _5508 = floor(_5502);\n    float2 param_2 = _5492;\n    float2 param_3 = _5496;\n    float2 param_4 = _5508;\n    float2 param_5 = _5492;\n    float2 param_6 = _5496;\n    float2 param_7 = _5508 + float2(1.0f, 0.0f);\n    float2 param_8 = _5492;\n    float2 param_9 = _5496;\n    float2 param_10 = _5508 + float2(0.0f, 1.0f);\n    float2 param_11 = _5492;\n    float2 param_12 = _5496;\n    float2 param_13 = _5508 + 1.0f.xx;\n    float3 _5550 = _5505.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5550), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5550), _5505.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5569 = max(_653_fa_tr_b.w - 1.0f, 0.0f);\n    float _5573 = clamp(lod, 0.0f, _5569);\n    int _5577 = int(floor(_5573));\n    int param = _5577;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5587 = float(_5577);\n    float _5588 = _5573 - _5587;\n    bool _5590 = _5588 > 0.001000000047497451305389404296875f;\n    bool _5597;\n    if (_5590)\n    {\n        _5597 = _5587 < _5569;\n    }\n    else\n    {\n        _5597 = _5590;\n    }\n    if (_5597)\n    {\n        int param_2 = _5577 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5588.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5623 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _5623.x) + (f90.xxx * _5623.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _5651 = max(s.thickness, 0.0f);\n    bool _5656 = _5651 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5656)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5651);\n    }\n    bool _5681 = _653_fa_tr_a.w > 1.5f;\n    bool _5688;\n    if (!_5681)\n    {\n        _5688 = _653_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5688 = _5681;\n    }\n    if (_5688)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_5656)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5651);\n    }\n    float4 _5723 = float4(world, 1.0f);\n    float _5728 = dot(_653_fa_ct_vpw, _5723);\n    float2 uv = 0.5f.xx;\n    if (_5728 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5746 = float2(dot(_653_fa_ct_vpx, _5723), dot(_653_fa_ct_vpy, _5723)) / _5728.xx;\n        float _5754;\n        if (_653_fa_ct_a.y > 0.5f)\n        {\n            _5754 = (_5746.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5754 = 0.5f - (_5746.y * 0.5f);\n        }\n        uv = float2((_5746.x * 0.5f) + 0.5f, _5754);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_653_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2315_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3269 = int(_2315_fa_shadow_cfg.x + 0.5f);\n    float _3279 = dot(world - _2315_fa_shadow_eye.xyz, _2315_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3284 = _3269 > 0;\n    bool _3293;\n    if (_3284)\n    {\n        int param = _3269 - 1;\n        _3293 = _3279 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3293 = _3284;\n    }\n    if (_3293)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3299 = _3269 > 1;\n        bool _3306;\n        if (_3299)\n        {\n            _3306 = _3279 > _2315_fa_shadow_split.x;\n        }\n        else\n        {\n            _3306 = _3299;\n        }\n        if (_3306)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3312 = _3269 > 2;\n        bool _3319;\n        if (_3312)\n        {\n            _3319 = _3279 > _2315_fa_shadow_split.y;\n        }\n        else\n        {\n            _3319 = _3312;\n        }\n        if (_3319)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3325 = _3269 > 3;\n        bool _3332;\n        if (_3325)\n        {\n            _3332 = _3279 > _2315_fa_shadow_split.z;\n        }\n        else\n        {\n            _3332 = _3325;\n        }\n        if (_3332)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _8703 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8703 = -_8703;\n    }\n    float3 _7986 = normalize(_653_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _8716 = { fa_world_pos, _8703, fa_world_tangent, fa_uv, fa_vertex_color, _7986, gl_FrontFacing };\n    SurfaceInput param_1 = _8716;\n    Surface _7994 = fa_standard_surface(param_1);\n    float3 _8734 = _7994.albedo;\n    float _8735 = _7994.alpha;\n    float3 _8736 = _7994.normal;\n    float _8737 = _7994.metallic;\n    float _8738 = _7994.roughness;\n    float _8739 = _7994.occlusion;\n    float3 _8740 = _7994.emission;\n    float _8741 = _7994.clearcoat;\n    float _8742 = _7994.clearcoat_roughness;\n    float3 _8743 = _7994.sheen_color;\n    float _8744 = _7994.sheen_roughness;\n    float _8745 = _7994.anisotropy;\n    float _8746 = _7994.anisotropy_rotation;\n    float _8747 = _7994.specular;\n    float _8748 = _7994.ior;\n    float3 _8749 = _7994.specular_color;\n    float _8750 = _7994.transmission;\n    float _8751 = _7994.thickness;\n    float3 _8752 = _7994.attenuation_color;\n    float _8753 = _7994.attenuation_distance;\n    SurfaceInput _8724 = { fa_world_pos, _8703, fa_world_tangent, fa_uv, fa_vertex_color, _7986, gl_FrontFacing };\n    SurfaceInput param_2 = _8724;\n    Surface param_3 = _7994;\n    surface(param_2, param_3);\n    _8734 = param_3.albedo;\n    _8735 = param_3.alpha;\n    _8736 = param_3.normal;\n    _8737 = param_3.metallic;\n    _8738 = param_3.roughness;\n    _8739 = param_3.occlusion;\n    _8740 = param_3.emission;\n    _8741 = param_3.clearcoat;\n    _8742 = param_3.clearcoat_roughness;\n    _8743 = param_3.sheen_color;\n    _8744 = param_3.sheen_roughness;\n    _8745 = param_3.anisotropy;\n    _8746 = param_3.anisotropy_rotation;\n    _8747 = param_3.specular;\n    _8748 = param_3.ior;\n    _8749 = param_3.specular_color;\n    _8750 = param_3.transmission;\n    _8751 = param_3.thickness;\n    _8752 = param_3.attenuation_color;\n    _8753 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _8703;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8734 = param_6;\n    _8736 = param_7;\n    if (_8735 < _8022_alphaCutoff)\n    {\n        discard;\n    }\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_653_fa_emissive.w > 0.5f)\n    {\n        result = _8734;\n    }\n    else\n    {\n        float3 _8045 = normalize(_8736);\n        float _8052 = clamp(_8737, 0.0f, 1.0f);\n        float _8056 = clamp(_8738, 0.0500000007450580596923828125f, 1.0f);\n        float _8060 = _8056 * _8056;\n        float _8064 = _8060 * _8060;\n        float _8069 = max(dot(_8045, _7986), 9.9999997473787516355514526367188e-05f);\n        float _8075 = 1.0f - _8052;\n        float _8076 = clamp(_8750, 0.0f, 1.0f) * _8075;\n        float3 _8085 = (_8734 * _8075) * (1.0f - _8076);\n        float3 _8092 = lerp(0.039999999105930328369140625f.xxx, _8734, _8052.xxx);\n        float3 f0 = _8092;\n        SurfaceInput _8732 = { fa_world_pos, _8703, fa_world_tangent, fa_uv, fa_vertex_color, _7986, gl_FrontFacing };\n        SurfaceInput param_8 = _8732;\n        Surface _8835 = { _8734, _8735, _8736, _8737, _8738, _8739, _8740, _8741, _8742, _8743, _8744, _8745, _8746, _8747, _8748, _8749, _8750, _8751, _8752, _8753 };\n        Surface param_9 = _8835;\n        float3 param_10 = _8045;\n        float3 param_11 = _7986;\n        float param_12 = _8052;\n        float param_13 = _8056;\n        float3 param_14 = _8092;\n        FaLayers _8108 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8045;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8085) * _8739;\n        if (_8108.on)\n        {\n            lit *= _8108.base_scale;\n        }\n        int _8130 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8130; ln++)\n        {\n            int param_16 = ln;\n            int _8143 = fa_cl_light(param_16);\n            int param_17 = _8143;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8143;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _8703;\n            LightSample _8159 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8167 = max(dot(_8045, _8159.direction), 0.0f);\n            float _8173 = _8159.attenuation * _8159.shadow;\n            float3 _8178 = normalize(_8159.direction + _7986);\n            float _8183 = max(dot(_8045, _8178), 0.0f);\n            float _8188 = max(dot(_7986, _8178), 0.0f);\n            bool _8195;\n            if (fa_light_is_area)\n            {\n                _8195 = !_8108.on;\n            }\n            else\n            {\n                _8195 = fa_light_is_area;\n            }\n            if (_8195)\n            {\n                int param_21 = _8143;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8045;\n                float3 param_24 = _7986;\n                float3 param_25 = _8085;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _8056;\n                float param_29 = _8069;\n                float param_30 = _8173;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8108;\n                    int param_32 = _8143;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _8045;\n                    float3 param_35 = _7986;\n                    float3 param_36 = _8159.direction;\n                    float3 param_37 = _8085;\n                    float3 param_38 = f0;\n                    float param_39 = _8056;\n                    float param_40 = _8069;\n                    float param_41 = _8173;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8108.on)\n                    {\n                        FaLayers param_42 = _8108;\n                        float3 param_43 = _8085;\n                        float3 param_44 = f0;\n                        float3 param_45 = _8045;\n                        float3 param_46 = _7986;\n                        float3 param_47 = _8159.direction;\n                        float3 param_48 = _8178;\n                        float param_49 = _8167;\n                        float param_50 = _8069;\n                        float param_51 = _8183;\n                        float param_52 = _8188;\n                        float param_53 = _8060;\n                        float param_54 = _8064;\n                        int param_55 = _8143;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8173));\n                    }\n                    else\n                    {\n                        float _8301 = ((_8183 * _8183) * (_8064 - 1.0f)) + 1.0f;\n                        int param_56 = _8143;\n                        lit += (((_8085 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8188, 5.0f))) * (((_8064 / ((3.1415927410125732421875f * _8301) * _8301)) * (0.5f / max(lerp((2.0f * _8167) * _8069, _8167 + _8069, _8060), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8167))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8167 * _8173));\n                    }\n                }\n            }\n        }\n        if (_8108.on)\n        {\n            FaLayers param_57 = _8108;\n            float3 param_58 = _8045;\n            float3 param_59 = _7986;\n            float3 param_60 = f0;\n            float param_61 = _8056;\n            float param_62 = _8739;\n            lit += fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, param_62);\n        }\n        else\n        {\n            float3 param_63 = _8045;\n            float3 param_64 = _7986;\n            float3 param_65 = f0;\n            float param_66 = _8056;\n            lit += (fa_sky_reflection(param_63, param_64, param_65, param_66) * _8739);\n        }\n        if (_8076 > 0.0f)\n        {\n            float _8399;\n            if (_8108.on)\n            {\n                _8399 = _8108.f90;\n            }\n            else\n            {\n                _8399 = 1.0f;\n            }\n            float _8407;\n            if (_8108.on)\n            {\n                _8407 = _8108.base_scale;\n            }\n            else\n            {\n                _8407 = 1.0f;\n            }\n            Surface _8856 = { _8734, _8735, _8736, _8737, _8738, _8739, _8740, _8741, _8742, _8743, _8744, _8745, _8746, _8747, _8748, _8749, _8750, _8751, _8752, _8753 };\n            Surface param_67 = _8856;\n            float3 param_68 = _8045;\n            float3 param_69 = _7986;\n            float param_70 = _8056;\n            float3 param_71 = f0;\n            float param_72 = _8399;\n            float param_73 = _8407;\n            float param_74 = _8076;\n            float param_75 = fa_tr_blend;\n            float3 _8431 = fa_transmitted(param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75);\n            fa_tr_blend = param_75;\n            lit += _8431;\n        }\n        result = lit;\n    }\n    float3 _8438 = result;\n    float3 _8439 = _8438 + _8740;\n    result = _8439;\n    float3 param_76 = _8439;\n    float3 param_77 = fa_world_pos;\n    result = fa_shadow_debug(param_76, param_77);\n    bool _8448 = _653_fa_fog.w > 0.0f;\n    bool _8455;\n    if (!_8448)\n    {\n        _8455 = _653_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8455 = _8448;\n    }\n    if (_8455)\n    {\n        float3 _8464 = fa_world_pos - _653_fa_camera_pos.xyz;\n        float _8470 = dot(_8464, _653_fa_fog_c.xyz);\n        bool _8474 = _653_fa_fog_c.w > 0.5f;\n        float _8475;\n        if (_8474)\n        {\n            _8475 = _8470;\n        }\n        else\n        {\n            _8475 = length(_8464);\n        }\n        float _8487 = _8475 - _653_fa_fog_b.x;\n        if (_8487 > 0.0f)\n        {\n            float _8496 = _653_fa_fog.w * _8487;\n            float tau = _8496 * _8496;\n            if (_653_fa_fog_b.y > 0.0f)\n            {\n                float _8512;\n                if (_8474)\n                {\n                    _8512 = fa_world_pos.y - (_653_fa_fog_c.y * _8470);\n                }\n                else\n                {\n                    _8512 = _653_fa_camera_pos.y;\n                }\n                float _8533 = lerp(_8512, fa_world_pos.y, clamp(_653_fa_fog_b.x / _8475, 0.0f, 1.0f));\n                float _8537 = fa_world_pos.y - _8533;\n                float _8542 = _8533 - _653_fa_fog_b.z;\n                float _8547 = fa_world_pos.y - _653_fa_fog_b.z;\n                bool _8550 = _8542 <= 0.0f;\n                bool _8551 = !_8550;\n                bool _8557;\n                if (_8551)\n                {\n                    _8557 = _653_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8557 = _8550;\n                }\n                float _8558;\n                if (_8557)\n                {\n                    _8558 = _653_fa_fog_b.y;\n                }\n                else\n                {\n                    _8558 = _653_fa_fog_b.y * exp(-min(_653_fa_fog_b.w * _8542, 80.0f));\n                }\n                bool _8585;\n                if (_8551)\n                {\n                    _8585 = _653_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8585 = _8550;\n                }\n                float _8586;\n                if (_8585)\n                {\n                    _8586 = _653_fa_fog_b.y * _8542;\n                }\n                else\n                {\n                    _8586 = (_653_fa_fog_b.y * (1.0f - exp(-min(_653_fa_fog_b.w * _8542, 80.0f)))) / _653_fa_fog_b.w;\n                }\n                bool _8611 = _8547 <= 0.0f;\n                bool _8618;\n                if (!_8611)\n                {\n                    _8618 = _653_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8618 = _8611;\n                }\n                float _8619;\n                if (_8618)\n                {\n                    _8619 = _653_fa_fog_b.y * _8547;\n                }\n                else\n                {\n                    _8619 = (_653_fa_fog_b.y * (1.0f - exp(-min(_653_fa_fog_b.w * _8547, 80.0f)))) / _653_fa_fog_b.w;\n                }\n                float _8646;\n                if (abs(_8537) < 0.001000000047497451305389404296875f)\n                {\n                    _8646 = _8558;\n                }\n                else\n                {\n                    _8646 = (_8619 - _8586) / _8537;\n                }\n                tau += (_8487 * max(_8646, 0.0f));\n            }\n            result = lerp(result, _653_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _8682 = 1.0f - fa_tr_blend;\n        result /= _8682.xxx;\n        _8735 *= _8682;\n    }\n    fa_frag_color = float4(result, _8735);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_653",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2315",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8022",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _390 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _390;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_397, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4353[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _653_fa_camera_pos : packoffset(c0);\n    float4 _653_fa_ambient : packoffset(c1);\n    float4 _653_fa_base_color : packoffset(c2);\n    float4 _653_fa_emissive : packoffset(c3);\n    float4 _653_fa_model_emissive : packoffset(c4);\n    float4 _653_fa_pbr : packoffset(c5);\n    float4 _653_fa_maps : packoffset(c6);\n    float4 _653_fa_fog : packoffset(c7);\n    float4 _653_fa_fog_b : packoffset(c8);\n    float4 _653_fa_fog_c : packoffset(c9);\n    float4 _653_fa_counts : packoffset(c10);\n    float4 _653_fa_env_sky : packoffset(c11);\n    float4 _653_fa_env_horizon : packoffset(c12);\n    float4 _653_fa_time : packoffset(c13);\n    float4 _653_fa_cl_vpx : packoffset(c14);\n    float4 _653_fa_cl_vpy : packoffset(c15);\n    float4 _653_fa_cl_vpw : packoffset(c16);\n    float4 _653_fa_cl_fwd : packoffset(c17);\n    float4 _653_fa_cl_grid : packoffset(c18);\n    float4 _653_fa_cl_info : packoffset(c19);\n    float4 _653_fa_layers_a : packoffset(c20);\n    float4 _653_fa_layers_b : packoffset(c21);\n    float4 _653_fa_layers_c : packoffset(c22);\n    float4 _653_fa_layers_d : packoffset(c23);\n    float4 _653_fa_ct_a : packoffset(c24);\n    float4 _653_fa_ct_b : packoffset(c25);\n    float4 _653_fa_ct_vpx : packoffset(c26);\n    float4 _653_fa_ct_vpy : packoffset(c27);\n    float4 _653_fa_ct_vpw : packoffset(c28);\n    float4 _653_fa_ct_fwd : packoffset(c29);\n    float4 _653_fa_tr_a : packoffset(c30);\n    float4 _653_fa_tr_b : packoffset(c31);\n    float4 _653_fa_probe_sh[9] : packoffset(c32);\n    float4 _653_fa_atlas : packoffset(c41);\n    float4 _653_fa_rpa_tile : packoffset(c42);\n    float4 _653_fa_rpa_pos : packoffset(c43);\n    float4 _653_fa_rpa_bx : packoffset(c44);\n    float4 _653_fa_rpa_by : packoffset(c45);\n    float4 _653_fa_rpa_bz : packoffset(c46);\n    float4 _653_fa_rpb_tile : packoffset(c47);\n    float4 _653_fa_rpb_pos : packoffset(c48);\n    float4 _653_fa_rpb_bx : packoffset(c49);\n    float4 _653_fa_rpb_by : packoffset(c50);\n    float4 _653_fa_rpb_bz : packoffset(c51);\n    float4 _653_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2315_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2315_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2315_fa_shadow_info[4] : packoffset(c20);\n    float4 _2315_fa_shadow_split : packoffset(c24);\n    float4 _2315_fa_shadow_cfg : packoffset(c25);\n    float4 _2315_fa_shadow_bias : packoffset(c26);\n    float4 _2315_fa_shadow_eye : packoffset(c27);\n    float4 _2315_fa_shadow_fwd : packoffset(c28);\n    float4 _2315_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8022_alphaCutoff : packoffset(c0);\n    float _8022_fa_pad0 : packoffset(c0.y);\n    float _8022_fa_pad1 : packoffset(c0.z);\n    float _8022_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1591 = _653_fa_cl_info.x < 0.0f;\n    bool _1598;\n    if (!_1591)\n    {\n        _1598 = _653_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1598 = _1591;\n    }\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = _653_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    bool _1613;\n    if (!_1606)\n    {\n        _1613 = _653_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1613 = _1606;\n    }\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = _653_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    if (_1620)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1630 = float4(world_pos, 1.0f);\n    float _1636 = dot(_653_fa_cl_vpw, _1630);\n    if (!(_1636 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1658 = float2(dot(_653_fa_cl_vpx, _1630), dot(_653_fa_cl_vpy, _1630)) / _1636.xx;\n    int _1662 = int(_653_fa_cl_grid.x);\n    int _1666 = int(_653_fa_cl_grid.y);\n    int param = (int(_653_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_653_fa_cl_fwd.xyz, world_pos) + _653_fa_cl_fwd.w, _653_fa_cl_grid.w) / _653_fa_cl_grid.w) * _653_fa_cl_grid.z)), 0, int(_653_fa_cl_info.y) - 1) * _1666) + clamp(int(floor(((_1658.y * 0.5f) + 0.5f) * _653_fa_cl_grid.y)), 0, _1666 - 1)) * _1662)) + clamp(int(floor(((_1658.x * 0.5f) + 0.5f) * _653_fa_cl_grid.x)), 0, _1662 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1742 = fa_cluster_texel(param);\n    return int2(int(_1742.x), int(_1742.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_653_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5828 = fa_cluster_lookup(param);\n    fa_cl_slot = _5828.x;\n    fa_cl_local = _5828.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6972 = fa_linear_to_srgb(param);\n        c = _6972;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6980 = fa_srgb_to_linear(param_1);\n            c = _6980;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _535;\n    if (i.front_facing)\n    {\n        _535 = i.world_normal;\n    }\n    else\n    {\n        _535 = -i.world_normal;\n    }\n    float3 _559 = normalize(i.world_tangent.xyz - (_535 * dot(_535, i.world_tangent.xyz)));\n    float3 _586 = normalize(((_559 * m.x) + ((cross(_535, _559) * i.world_tangent.w) * m.y)) + (_535 * m.z));\n    float3 _589;\n    if (i.front_facing)\n    {\n        _589 = _586;\n    }\n    else\n    {\n        _589 = -_586;\n    }\n    return _589;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _653_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7011 = fa_tex_fix(param_2, param_3);\n    float4 _9280 = base_t;\n    _9280.x = _7011.x;\n    _9280.y = _7011.y;\n    _9280.z = _7011.z;\n    base_t = _9280;\n    float4 _7025 = (_9280 * _653_fa_base_color) * i.vertex_color;\n    float3 _9064 = i.world_normal;\n    if (_653_fa_maps.z > 0.5f)\n    {\n        float param_4 = _653_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7057 = fa_tex_fix(param_6, param_7);\n        float3 _7060 = (_7057 * 2.0f) - 1.0f.xxx;\n        float2 _7065 = _7060.xy * _653_fa_maps.x;\n        float3 _9288 = _7060;\n        _9288.x = _7065.x;\n        _9288.y = _7065.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9288;\n        _9064 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _653_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7093 = fa_tex_fix(param_12, param_13);\n    float4 _9291 = mrt;\n    _9291.x = _7093.x;\n    _9291.y = _7093.y;\n    _9291.z = _7093.z;\n    mrt = _9291;\n    float4 _7121 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _653_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7121.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7132 = fa_tex_fix(param_16, param_17);\n    float param_18 = _653_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7162 = fa_tex_fix(param_20, param_21);\n    float _9069 = _653_fa_layers_a.x;\n    float _9070 = _653_fa_layers_a.y;\n    float _9073 = _653_fa_layers_a.z;\n    float _9072 = _653_fa_layers_b.w;\n    float _9075 = _653_fa_layers_c.x;\n    if (_653_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_653_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9069 *= _7132.y;\n            _9070 *= _7132.z;\n            _9072 *= _7121.w;\n        }\n        if (_653_fa_layers_c.z > 1.5f)\n        {\n            _9073 *= mrt.x;\n            _9075 *= mrt.w;\n        }\n    }\n    Surface _9102 = { _7025.xyz, _7025.w, _9064, clamp(_653_fa_pbr.x * _7093.z, 0.0f, 1.0f), clamp(_653_fa_pbr.y * _7093.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_653_fa_maps.y * (_7132.x - 1.0f)), _653_fa_emissive.xyz + (_653_fa_model_emissive.xyz * _7162), _9069, _9070, _653_fa_layers_b.xyz, _9072, _9073, _653_fa_layers_a.w, _9075, _653_fa_layers_c.y, _653_fa_layers_d.xyz, _653_fa_tr_a.x, _653_fa_tr_a.y, _653_fa_tr_b.xyz, _653_fa_tr_a.z };\n    return _9102;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1822 = rect.zw - rect.xy;\n    float2 _1826 = _1822 * atlas;\n    float2 _1830 = ddx * _1826;\n    float2 _1834 = ddy * _1826;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1822), clamp(0.5f * log2(max(max(dot(_1830, _1830), dot(_1834, _1834)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1867 = _653_fa_counts.y < 0.5f;\n    bool _1874;\n    if (!_1867)\n    {\n        _1874 = _653_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1874 = _1867;\n    }\n    if (_1874)\n    {\n        return;\n    }\n    float3 _1880 = ddx(world_pos);\n    float3 _1883 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1887 = fa_cluster_texel(param);\n    int _1891 = int(_1887.w);\n    if (_1891 < 1)\n    {\n        return;\n    }\n    int _1901 = int(_653_fa_counts.y + 0.5f);\n    int param_1 = _1901;\n    float4 _1905 = fa_light_texel(param_1);\n    float2 _1908 = _1905.yz;\n    int _1912 = int(_1905.w);\n    int param_2 = _1901 + 1;\n    float4 _1917 = fa_light_texel(param_2);\n    float _1918 = _1917.x;\n    int _1924 = int(_653_fa_counts.w + 0.5f) - 1;\n    int _1928 = int(_1887.z);\n    float3 _2193;\n    for (int k = 0; k < _1891; k++)\n    {\n        int _1941 = _1928 + k;\n        int param_3 = _1912 + (_1941 >> 2);\n        int _1958 = (_1901 + 2) + (int(fa_light_texel(param_3)[_1941 & 3]) * 7);\n        int param_4 = _1958 + 6;\n        float4 _1963 = fa_light_texel(param_4);\n        if (((int(_1963.w + 0.5f) >> _1924) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1958;\n        float4 _1978 = fa_light_texel(param_5);\n        int param_6 = _1958 + 1;\n        float4 _1983 = fa_light_texel(param_6);\n        int param_7 = _1958 + 2;\n        float4 _1988 = fa_light_texel(param_7);\n        float3 _1991 = _1978.xyz;\n        float _1996 = dot(_1991, world_pos) + _1978.w;\n        float3 _1998 = _1983.xyz;\n        float _2003 = dot(_1998, world_pos) + _1983.w;\n        float3 _2005 = _1988.xyz;\n        float _2010 = dot(_2005, world_pos) + _1988.w;\n        bool _2015 = abs(_1996) > 0.5f;\n        bool _2023;\n        if (!_2015)\n        {\n            _2023 = abs(_2003) > 0.5f;\n        }\n        else\n        {\n            _2023 = _2015;\n        }\n        bool _2031;\n        if (!_2023)\n        {\n            _2031 = abs(_2010) > 0.5f;\n        }\n        else\n        {\n            _2031 = _2023;\n        }\n        if (_2031)\n        {\n            continue;\n        }\n        float _2046 = clamp(dot(geo_normal, normalize(_2005)) * _1963.z, 0.0f, 1.0f);\n        if (_2046 <= 0.0f)\n        {\n            continue;\n        }\n        float _2066 = (clamp((0.5f - abs(_2010)) * 10.0f, 0.0f, 1.0f) * _2046) * _1963.x;\n        float2 _2074 = float2(_1996 + 0.5f, 0.5f - _2003);\n        float2 _2084 = float2(dot(_1991, _1880), dot(_1998, _1880));\n        float2 _2094 = float2(dot(_1991, _1883), dot(_1998, _1883));\n        int param_8 = _1958 + 5;\n        float4 _2099 = fa_light_texel(param_8);\n        int param_9 = _1958 + 3;\n        float4 _2104 = fa_light_texel(param_9);\n        int param_10 = _1958 + 4;\n        float4 _2109 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2099.xyz;\n        bool _2119 = _2104.z > _2104.x;\n        if (_2119)\n        {\n            float4 param_11 = _2104;\n            float2 param_12 = _2074;\n            float2 param_13 = _1908;\n            float2 param_14 = _2084;\n            float2 param_15 = _2094;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1918 > 0.5f) && (_1918 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2145 = fa_dc_to_linear(param_16);\n                float4 _9152 = tx;\n                _9152.x = _2145.x;\n                _9152.y = _2145.y;\n                _9152.z = _2145.z;\n                tx = _9152;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2066 * tex_a) * _2099.w, 0.0f, 1.0f).xxx);\n        if (_2109.z > _2109.x)\n        {\n            float4 param_17 = _2109;\n            float2 param_18 = _2074;\n            float2 param_19 = _1908;\n            float2 param_20 = _2084;\n            float2 param_21 = _2094;\n            float4 _2189 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1918 > 1.5f)\n            {\n                float3 param_22 = _2189.xyz;\n                float3 _2199 = fa_dc_to_srgb(param_22);\n                _2193 = _2199;\n            }\n            else\n            {\n                _2193 = _2189.xyz;\n            }\n            float3 _2208 = (_2193 * 2.0f) - 1.0f.xxx;\n            float2 _2213 = _2208.xy * _1963.y;\n            float3 _2235 = (normalize(_1991) * _2213.x) + (normalize(_1998) * _2213.y);\n            float3 _2238 = normalize(normal);\n            normal = normalize(lerp(_2238, normalize((_2238 * max(_2208.z, 0.0500000007450580596923828125f)) + (_2235 - (_2238 * dot(_2238, _2235)))), clamp(_2066 * (_2119 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4278 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4286 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4289 = int(_4278);\n    int _4292 = int(_4286);\n    float _4302 = _4286 - float(_4292);\n    int _4357 = (_4289 * 9) + _4292;\n    int _4377 = ((_4289 + 1) * 9) + _4292;\n    return lerp(lerp(_4353[_4357], _4353[_4357 + 1], _4302), lerp(_4353[_4377], _4353[_4377 + 1], _4302), _4278 - float(_4289));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _8987 = false;\n    float _8988 = 1.0f;\n    float _8989 = 1.0f;\n    float _8990 = 1.0f;\n    float _8991 = 0.0f;\n    float _8992 = 0.0f;\n    float _8993 = 0.0f;\n    float _8994 = 0.0f;\n    float _8996 = 1.0f;\n    bool _8997 = false;\n    float3 _8998 = 0.0f.xxx;\n    float _8999 = 1.0f;\n    float _9000 = 1.0f;\n    float _9001 = 1.0f;\n    float _9002 = 0.0f;\n    float _9003 = 0.0f;\n    float3 _9004 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9005 = float3(0.0f, 0.0f, 1.0f);\n    float _9006 = 1.0f;\n    float _9007 = 1.0f;\n    float _4428 = clamp(s.specular, 0.0f, 1.0f);\n    float _4432 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4437 = (_4428 != 1.0f) || (_4432 != 1.5f);\n    bool _4446;\n    if (!_4437)\n    {\n        _4446 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4446 = _4437;\n    }\n    if (_4446)\n    {\n        float _4454 = (_4432 - 1.0f) / (_4432 + 1.0f);\n        f0 = lerp(min((_4454 * _4454).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4428, s.albedo, metallic.xxx);\n        _8988 = lerp(_4428, 1.0f, metallic);\n        _8987 = true;\n    }\n    float _4481 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4481 > 0.0f)\n    {\n        float _4489 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _8991 = _4481;\n        _8992 = _4489;\n        float _4496 = _4489 * _4489;\n        _8993 = _4496;\n        _8994 = _4496 * _4496;\n        float _4508 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _8996 = _4508;\n        _8989 = 1.0f - (_4481 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4508, 0.0f, 1.0f), 5.0f))));\n        _8987 = true;\n    }\n    float3 _4527 = max(s.sheen_color, 0.0f.xxx);\n    float _4536 = max(_4527.x, max(_4527.y, _4527.z));\n    if (_4536 > 0.0f)\n    {\n        float _4544 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _8997 = true;\n        _8998 = _4527;\n        _8999 = _4544;\n        _9000 = _4544 * _4544;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4544;\n        float _4561 = fa_sheen_albedo(param, param_1);\n        _9002 = _4561;\n        _9001 = 1.0f - min(_4536 * _4561, 1.0f);\n        _8987 = true;\n    }\n    _8990 = _8989 * _9001;\n    float _4580 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4580 != 0.0f)\n    {\n        float3 _4595 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4595;\n        if (dot(_4595, _4595) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4607 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4607.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4607.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4607.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4611 = t;\n        float3 _4612 = normalize(_4611);\n        t = _4612;\n        float3 _4637 = normalize((_4612 * cos(s.anisotropy_rotation)) + ((cross(n, _4612) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9004 = _4637;\n        _9005 = cross(n, _4637);\n        float _4647 = roughness * roughness;\n        float _4653 = lerp(_4647, 1.0f, _4580 * _4580);\n        bool _4655 = _4580 > 0.0f;\n        _9006 = _4655 ? _4653 : _4647;\n        _9007 = _4655 ? _4647 : _4653;\n        _9003 = _4580;\n        _8987 = true;\n    }\n    FaLayers _9029 = { _8987, _8988, _8989, _8990, _8991, _8992, _8993, _8994, i.world_normal, _8996, _8997, _8998, _8999, _9000, _9001, _9002, _9003, _9004, _9005, _9006, _9007 };\n    return _9029;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3505_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3505_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_653_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3446 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3446;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4059 = (1.0f - _653_fa_rpa_tile.w) - _653_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4064 = _653_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4059 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4064)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _653_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4059;\n            }\n        }\n        else\n        {\n            amb = _653_fa_ambient.xyz * _4059;\n        }\n    }\n    bool _4115 = _653_fa_rpa_tile.w > 0.0f;\n    if (_4115)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _653_fa_rpa_tile.xy;\n            float param_4 = _653_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _653_fa_rpa_tile.w);\n        }\n    }\n    bool _4146 = _653_fa_rpb_tile.w > 0.0f;\n    if (_4146)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _653_fa_rpb_tile.xy;\n            float param_7 = _653_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _653_fa_rpb_tile.w);\n        }\n    }\n    if ((_4064 || _4115) || _4146)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3466 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3469 = _3466.x;\n    float _3471 = _3466.z;\n    float2 e = float2(_3469, _3471);\n    if (_3466.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3471)) * ((_3469 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3469)) * ((_3471 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7272 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7277 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7282 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7287 = fa_light_texel(param_3);\n    bool _7290 = _7287.z < 0.5f;\n    bool _7298;\n    if (!_7290)\n    {\n        _7298 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7298 = _7290;\n    }\n    if (_7298)\n    {\n        return 0.0f.xxx;\n    }\n    float _7305 = max(_7272.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7308 = _7277.xyz;\n    float3 _7312 = _7272.xyz;\n    float3 _7316 = (fa_world_pos - _7312) / _7305.xxx;\n    float3 _7325 = min(_7316 + 0.5f.xxx, (_7308 - 0.5f.xxx) - _7316);\n    float _7334 = min(_7325.x, min(_7325.y, _7325.z));\n    if (!(_7334 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7349 = _7308 - 1.0f.xxx;\n    float3 _7350 = clamp(_7316, 0.0f.xxx, _7349);\n    float3 _7358 = min(floor(_7350), max(_7308 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7362 = _7350 - _7358;\n    float3 _7373 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7305));\n    int _7378 = int(_7282.y + 0.5f);\n    float _7383 = 0.3257350027561187744140625f * n.y;\n    float _7387 = 0.3257350027561187744140625f * n.z;\n    float _7391 = 0.3257350027561187744140625f * n.x;\n    float _7398 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _7405 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _7414 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _7421 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _7434 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _7441 = 8 + int(_7287.w);\n    float _7468;\n    float _7481;\n    float _7495;\n    for (int k = 0; k < _7441; k++)\n    {\n        float _7454 = float(k & 1);\n        float _7458 = float((k >> 1) & 1);\n        float _7462 = float((k >> 2) & 1);\n        if (_7454 > 0.5f)\n        {\n            _7468 = _7362.x;\n        }\n        else\n        {\n            _7468 = 1.0f - _7362.x;\n        }\n        if (_7458 > 0.5f)\n        {\n            _7481 = _7362.y;\n        }\n        else\n        {\n            _7481 = 1.0f - _7362.y;\n        }\n        if (_7462 > 0.5f)\n        {\n            _7495 = _7362.z;\n        }\n        else\n        {\n            _7495 = 1.0f - _7362.z;\n        }\n        float _7505 = (_7468 * _7481) * _7495;\n        if (!(_7505 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7518 = min(_7358 + float3(_7454, _7458, _7462), _7349);\n        int _7538 = int(((_7282.x + _7518.x) + (_7277.x * (_7518.y + (_7277.y * _7518.z)))) + 0.5f);\n        float2 _7553 = float2(float(_7538 % _7378) * 10.0f, 1024.0f + (float(_7538 / _7378) * 11.0f));\n        float2 param_4 = _7553 + float2(9.5f, 10.5f);\n        float4 _7561 = fa_gi_fetch(param_4);\n        bool _7564 = _7561.y < 0.5f;\n        bool _7573;\n        if (!_7564)\n        {\n            _7573 = _7561.x > _7287.y;\n        }\n        else\n        {\n            _7573 = _7564;\n        }\n        if (_7573)\n        {\n            continue;\n        }\n        float3 _7585 = _7373 - (_7312 + (_7518 * _7305));\n        float _7588 = length(_7585);\n        float3 _7594 = _7585 / max(_7588, 9.9999997473787516355514526367188e-05f).xxx;\n        float _7604 = max(9.9999997473787516355514526367188e-05f, (dot(-_7594, n) + 1.0f) * 0.5f);\n        float w = _7505 * (_7604 * _7604);\n        float3 param_5 = _7594;\n        float2 param_6 = (_7553 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _7623 = fa_gi_fetch(param_6);\n        float _7630 = _7588 / max(_7282.z, 9.9999997473787516355514526367188e-05f);\n        float _7633 = _7623.x;\n        if (_7630 > _7633)\n        {\n            float _7646 = max(_7623.y - (_7633 * _7633), 0.0f);\n            float _7651 = _7630 - _7633;\n            float _7660 = _7646 / max(_7646 + (_7651 * _7651), 9.9999999600419720025001879548654e-13f);\n            w *= ((_7660 * _7660) * _7660);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _7553 + float2(0.5f, 10.5f);\n        float2 param_8 = _7553 + float2(1.5f, 10.5f);\n        float2 param_9 = _7553 + float2(2.5f, 10.5f);\n        float2 param_10 = _7553 + float2(3.5f, 10.5f);\n        float2 param_11 = _7553 + float2(4.5f, 10.5f);\n        float2 param_12 = _7553 + float2(5.5f, 10.5f);\n        float2 param_13 = _7553 + float2(6.5f, 10.5f);\n        float2 param_14 = _7553 + float2(7.5f, 10.5f);\n        float2 param_15 = _7553 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _7383)) + (fa_gi_fetch(param_9).xyz * _7387)) + (fa_gi_fetch(param_10).xyz * _7391)) + (fa_gi_fetch(param_11).xyz * _7398)) + (fa_gi_fetch(param_12).xyz * _7405)) + (fa_gi_fetch(param_13).xyz * _7414)) + (fa_gi_fetch(param_14).xyz * _7421)) + (fa_gi_fetch(param_15).xyz * _7434)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7334 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _7785;\n    if (_653_fa_gi.z > 0.5f)\n    {\n        _7785 = _7287.x;\n    }\n    else\n    {\n        _7785 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7282.w * _7785);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _7809 = normalize(_653_fa_camera_pos.xyz - fa_world_pos);\n    int _7814 = int(_653_fa_gi.x + 0.5f);\n    int _7819 = int(_653_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _7819) && (k < 8); k++)\n    {\n        int param = _7814 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _7809;\n        float3 _7844 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7849 = param_3 * left;\n        acc += (_7844 * _7849);\n        left -= _7849;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_653_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _7878 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7878;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_653_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _653_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_653_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_653_fa_cl_info.x) + int(_653_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_653_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5798;\n    if (fa_lm.z > 0.5f)\n    {\n        _5798 = 0.0f;\n    }\n    else\n    {\n        _5798 = 1.0f - clamp(_653_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5809 = _5798 < 1.0f;\n    bool _5815;\n    if (_5809)\n    {\n        int param = li;\n        _5815 = fa_light_baked(param);\n    }\n    else\n    {\n        _5815 = _5809;\n    }\n    return _5815 ? _5798 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _721_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _721_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _840 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _853 = (c - (ru * hx)) - p;\n        float3 _859 = ru * (2.0f * hx);\n        float _865 = max(dot(_859, _859), 9.9999999392252902907785028219223e-09f);\n        float _869 = dot(_853, _859);\n        float t = clamp((-_869) / _865, 0.0f, 1.0f);\n        if (_840)\n        {\n            float _884 = dot(r, _859);\n            float _890 = _865 - (_884 * _884);\n            if (abs(_890) > (9.9999997473787516355514526367188e-06f * _865))\n            {\n                t = clamp(((dot(r, _853) * _884) - _869) / _890, 0.0f, 1.0f);\n            }\n        }\n        return (p + _853) + (_859 * t);\n    }\n    float3 q = p;\n    float _922 = dot(r, axis);\n    bool _930;\n    if (_840)\n    {\n        _930 = abs(_922) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _930 = _840;\n    }\n    if (_930)\n    {\n        float _940 = dot(c - p, axis) / _922;\n        if (_940 > 0.0f)\n        {\n            q = p + (r * _940);\n        }\n    }\n    float3 _953 = q - c;\n    float2 xy = float2(dot(_953, ru), dot(_953, uu));\n    if (shape > 0.5f)\n    {\n        float _968 = length(xy);\n        if (_968 > hx)\n        {\n            xy *= (hx / _968);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _601 = abs(d);\n    float _603 = _601.x;\n    float _605 = _601.y;\n    bool _606 = _603 >= _605;\n    bool _614;\n    if (_606)\n    {\n        _614 = _603 >= _601.z;\n    }\n    else\n    {\n        _614 = _606;\n    }\n    int _615;\n    if (_614)\n    {\n        _615 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _630;\n        if (_605 >= _601.z)\n        {\n            _630 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _630 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _615 = _630;\n    }\n    return _615;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _760 = dot(d, right);\n    float _764 = dot(d, up);\n    float _775;\n    if (((_760 * _760) + (_764 * _764)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _775 = atan2(_764, _760) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _775 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_775 - floor(_775)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1006 = fa_light_base(param);\n    bool _1010 = _653_fa_ambient.w > 4.5f;\n    int param_1 = _1006;\n    float4 _1014 = fa_light_texel(param_1);\n    int param_2 = _1006 + 1;\n    float4 _1019 = fa_light_texel(param_2);\n    float _1022 = _1019.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1034 = _1010 && (_1022 > 2.5f);\n    fa_light_is_area = _1034;\n    bool _1036 = _1022 < 0.5f;\n    float3 l;\n    if (_1036)\n    {\n        l = normalize(_1014.xyz);\n        if (_1010)\n        {\n            int param_3 = _1006 + 6;\n            float4 _1050 = fa_light_texel(param_3);\n            if (_1050.z > 0.5f)\n            {\n                int param_4 = _1006 + 4;\n                float4 _1060 = fa_light_texel(param_4);\n                int param_5 = _1006 + 5;\n                float4 _1065 = fa_light_texel(param_5);\n                float2 param_6 = _1050.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1060.xyz) * _1060.w, (-dot(world_pos, _1065.xyz)) * _1065.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1095 = _1014.xyz;\n        float3 _1097 = _1095 - world_pos;\n        float3 to_light = _1097;\n        float _1100 = length(_1097);\n        float reach = _1100;\n        bool front = true;\n        if (_1034)\n        {\n            int param_8 = _1006 + 7;\n            reach = max(_1100 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1006 + 4;\n            float4 _1124 = fa_light_texel(param_9);\n            int param_10 = _1006 + 5;\n            float4 _1129 = fa_light_texel(param_10);\n            int param_11 = _1006 + 6;\n            float4 _1134 = fa_light_texel(param_11);\n            float _1135 = _1134.w;\n            int param_12 = _1006 + 2;\n            float3 _1142 = normalize(fa_light_texel(param_12).xyz);\n            bool _1144 = _1135 > 1.5f;\n            bool _1152;\n            if (!_1144)\n            {\n                _1152 = dot(_1142, to_light) < 0.0f;\n            }\n            else\n            {\n                _1152 = _1144;\n            }\n            front = _1152;\n            float3 r = 0.0f.xxx;\n            float3 _1161 = _653_fa_camera_pos.xyz - world_pos;\n            bool _1165 = dot(n, n) > 0.5f;\n            bool _1173;\n            if (_1165)\n            {\n                _1173 = dot(_1161, _1161) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1173 = _1165;\n            }\n            if (_1173)\n            {\n                r = reflect(-normalize(_1161), normalize(n));\n            }\n            float3 param_13 = _1095;\n            float3 param_14 = _1142;\n            float3 param_15 = _1124.xyz;\n            float3 param_16 = _1129.xyz;\n            float param_17 = _1124.w;\n            float param_18 = _1129.w;\n            float param_19 = _1135;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1209 = length(to_light);\n        dist = _1209;\n        l = to_light / max(_1209, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1223 = reach / max(_1014.w, 0.001000000047497451305389404296875f);\n        float _1229 = clamp(1.0f - (_1223 * _1223), 0.0f, 1.0f);\n        float _1231;\n        if (front)\n        {\n            _1231 = _1229 * _1229;\n        }\n        else\n        {\n            _1231 = 0.0f;\n        }\n        atten = _1231;\n        bool _1242 = _1022 < 2.5f;\n        if ((_1022 > 1.5f) && _1242)\n        {\n            int param_22 = _1006 + 2;\n            float4 _1250 = fa_light_texel(param_22);\n            float _1260 = _1250.w;\n            int param_23 = _1006 + 3;\n            float4 _1265 = fa_light_texel(param_23);\n            float _1266 = _1265.x;\n            float cos_inner = _1266;\n            if (_1266 > 1.5f)\n            {\n                cos_inner = lerp(_1260, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1260, cos_inner, dot(-l, normalize(_1250.xyz)));\n        }\n        if (_1010 && (_1022 < 1.5f))\n        {\n            int param_24 = _1006 + 6;\n            float4 _1290 = fa_light_texel(param_24);\n            if (_1290.z > 0.5f)\n            {\n                float3 _1298 = -to_light;\n                int param_25 = _1006 + 4;\n                int param_26 = _1006 + 5;\n                float3 _1312 = fa_light_texel(param_25).xyz;\n                float3 _1316 = fa_light_texel(param_26).xyz;\n                float3 _1325 = float3(dot(_1298, _1312), dot(_1298, _1316), dot(_1298, cross(_1312, _1316)));\n                float3 param_27 = _1325;\n                int _1329 = fa_cube_face(param_27);\n                int param_28 = _1329;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1356 = float2(dot(_1325, cross(param_29, param_30)), dot(_1325, param_30)) / max(dot(_1325, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1360 = _1329 / 3;\n                float2 param_31 = _1290.xy + (float2(float(_1329 - (_1360 * 3)), float(_1360)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1356.x), 0.5f - (0.5f * _1356.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1006 + 7;\n            float4 _1390 = fa_light_texel(param_33);\n            if (_1390.z > 0.5f)\n            {\n                int param_34 = _1006 + 2;\n                int param_35 = _1006 + 4;\n                int param_36 = _1006 + 5;\n                float2 param_37 = _1390.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1010 && _1242)\n            {\n                int param_42 = _1006 + 6;\n                float4 _1437 = fa_light_texel(param_42);\n                int param_43 = _1006 + 7;\n                float4 _1442 = fa_light_texel(param_43);\n                bool _1445 = _1437.z > 0.5f;\n                bool _1452;\n                if (!_1445)\n                {\n                    _1452 = _1442.z > 0.5f;\n                }\n                else\n                {\n                    _1452 = _1445;\n                }\n                if (_1452)\n                {\n                    int param_44 = _1006 + 2;\n                    float4 _1459 = fa_light_texel(param_44);\n                    float3 _1463 = normalize(_1459.xyz);\n                    int param_45 = _1006 + 4;\n                    float4 _1468 = fa_light_texel(param_45);\n                    int param_46 = _1006 + 5;\n                    float4 _1473 = fa_light_texel(param_46);\n                    if (_1445)\n                    {\n                        float3 _1481 = -to_light;\n                        float _1488 = _1459.w;\n                        float _1504 = 0.5f / max(dot(_1481, _1463) * (sqrt(max(1.0f - (_1488 * _1488), 0.0f)) / max(_1488, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1437.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1481, _1468.xyz) * _1504), 0.5f - (dot(_1481, _1473.xyz) * _1504));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1442.z > 0.5f)\n                    {\n                        float2 param_49 = _1442.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1463;\n                        float3 param_52 = _1468.xyz;\n                        float3 param_53 = _1473.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _8975 = _1019.xyz * atten;\n    if (_1010)\n    {\n        _8975 *= fa_light_tint;\n    }\n    int _1573;\n    if (_1036)\n    {\n        _1573 = 0;\n    }\n    else\n    {\n        _1573 = ((_1022 > 1.5f) && (_1022 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _8986 = { l, _8975, atten, 1.0f, dist, _1573 };\n    return _8986;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2305;\n    if (i == 0)\n    {\n        _2305 = _2315_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2321;\n        if (i == 1)\n        {\n            _2321 = _2315_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2329;\n            if (i == 2)\n            {\n                _2329 = _2315_fa_shadow_split.z;\n            }\n            else\n            {\n                _2329 = _2315_fa_shadow_split.w;\n            }\n            _2321 = _2329;\n        }\n        _2305 = _2321;\n    }\n    return _2305;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2362 = fa_shadow_depth(param, param_1);\n    float _2366;\n    if (conv.x < 0.5f)\n    {\n        _2366 = _2362;\n    }\n    else\n    {\n        _2366 = (conv.y * conv.z) / (conv.z - (_2362 * (conv.z - conv.y)));\n    }\n    return _2366;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2412 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2418 = float2(cos(_2412), sin(_2412));\n    float2 dir = _2418;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2427;\n        if (k < 0.0f)\n        {\n            _2427 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2427 = k;\n        }\n        float _2446 = clamp((_2427 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2465 = sqrt((float(i) + 0.5f) * 0.0625f) * _2446;\n            float2 param_3 = uv + (dir * (_2315_fa_shadow_bias.zw * _2465));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2479 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2479 < (zr - (_2465 * plane)))\n            {\n                sum += _2479;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2507 = sum / cnt;\n        float _2517;\n        if (k < 0.0f)\n        {\n            _2517 = (-k) / max(_2507, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2517 = k;\n        }\n        radius = clamp(((max(zr - _2507, 0.0f) * unit) * _2517) / texel_m, 1.5f, 16.0f);\n        dir = _2418;\n    }\n    float lit = 0.0f;\n    int _2543 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2543; i_1++)\n    {\n        float _2562 = sqrt((float(i_1) + 0.5f) / float(_2543)) * radius;\n        float2 param_7 = uv + (dir * (_2315_fa_shadow_bias.zw * _2562));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2562 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2543);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2608 = max(_2315_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2613 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2619 = sqrt(1.0f - (_2613 * _2613));\n    float _2627 = min(_2619 / max(_2613, 0.20000000298023223876953125f), 4.0f);\n    float _2632;\n    if (_2315_fa_shadow_bias.y > 0.0f)\n    {\n        _2632 = _2315_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2632 = 1.5f * _2315_fa_shadow_info[ci].x;\n    }\n    float4 _2657 = mul(float4(world + (n * (_2632 * _2619)), 1.0f), _2315_fa_shadow_mat[ci]);\n    float _2664 = _2657.x;\n    bool _2667 = _2664 < _2315_fa_shadow_rect[ci].x;\n    bool _2676;\n    if (!_2667)\n    {\n        _2676 = _2664 > _2315_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2676 = _2667;\n    }\n    bool _2685;\n    if (!_2676)\n    {\n        _2685 = _2657.y < _2315_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2685 = _2676;\n    }\n    bool _2694;\n    if (!_2685)\n    {\n        _2694 = _2657.y > _2315_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2694 = _2685;\n    }\n    bool _2701;\n    if (!_2694)\n    {\n        _2701 = _2657.z > 1.0f;\n    }\n    else\n    {\n        _2701 = _2694;\n    }\n    if (_2701)\n    {\n        return -1.0f;\n    }\n    float _2709;\n    if (_2315_fa_shadow_bias.x > 0.0f)\n    {\n        _2709 = _2315_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2709 = 1.5f * _2315_fa_shadow_info[ci].x;\n    }\n    float2 param = _2657.xy;\n    float4 param_1 = _2315_fa_shadow_rect[ci];\n    float param_2 = _2657.z - ((_2709 * (1.0f + (0.5f * _2627))) / _2608);\n    float param_3 = _2315_fa_shadow_info[ci].x;\n    float param_4 = _2608;\n    float param_5 = _2608 * 0.25f;\n    float param_6 = ((_2315_fa_shadow_info[ci].x * min(_2627, 3.0f)) * 0.5f) / _2608;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2315_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2315_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_653_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3087 = int(_2315_fa_shadow_cfg.x + 0.5f);\n    if (_3087 < 1)\n    {\n        return 1.0f;\n    }\n    float _3102 = dot(world - _2315_fa_shadow_eye.xyz, _2315_fa_shadow_fwd.xyz);\n    int param = _3087 - 1;\n    if (_3102 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3114 = _3087 > 1;\n    bool _3121;\n    if (_3114)\n    {\n        _3121 = _3102 > _2315_fa_shadow_split.x;\n    }\n    else\n    {\n        _3121 = _3114;\n    }\n    if (_3121)\n    {\n        ci = 1;\n    }\n    bool _3125 = _3087 > 2;\n    bool _3132;\n    if (_3125)\n    {\n        _3132 = _3102 > _2315_fa_shadow_split.y;\n    }\n    else\n    {\n        _3132 = _3125;\n    }\n    if (_3132)\n    {\n        ci = 2;\n    }\n    bool _3136 = _3087 > 3;\n    bool _3143;\n    if (_3136)\n    {\n        _3143 = _3102 > _2315_fa_shadow_split.z;\n    }\n    else\n    {\n        _3143 = _3136;\n    }\n    if (_3143)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3087)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3169 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3169;\n        if (_3169 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2315_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3194;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3194 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3194 = _2315_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3213 = _2315_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3194, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3224 = clamp((_3102 - (fa_shadow_split_at(param_7) - _3213)) / _3213, 0.0f, 1.0f);\n        if (_3224 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3087)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3245 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3245;\n                if (_3245 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3224);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2767 = _653_fa_pbr.z < 0.5f;\n    bool _2774;\n    if (!_2767)\n    {\n        _2774 = _2315_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2774 = _2767;\n    }\n    if (_2774)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2315_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2787 = fa_light_texel(param);\n    float _2788 = _2787.x;\n    if (_2788 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2797 = int(_2788 + 0.5f);\n    int param_1 = _2797;\n    float4 _2801 = fa_light_texel(param_1);\n    int param_2 = _2797 + 1;\n    float4 _2806 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2809 = _2801.y;\n    if (_2809 > 0.0f)\n    {\n        float _2826 = 1.0f - smoothstep(0.75f * _2809, _2809, length(world - _2315_fa_shadow_eye.xyz));\n        fade = _2826;\n        if (_2826 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2801.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2850 = (_2797 + 2) + (face * 6);\n    int param_4 = _2850;\n    int param_5 = _2850 + 1;\n    int param_6 = _2850 + 3;\n    float4 _2864 = fa_light_texel(param_6);\n    int param_7 = _2850 + 4;\n    float4 _2869 = fa_light_texel(param_7);\n    int param_8 = _2850 + 5;\n    float4 _2874 = fa_light_texel(param_8);\n    float _2886 = _2874.x * max(dot(_2864, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2891 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2914 = clamp(dot(n, _2864.xyz), -1.0f, 1.0f);\n    float _2933 = min(sqrt(1.0f - (_2914 * _2914)) / max(abs(dot(n, world - lpos)) / max(dot(_2864, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2936 = _2806.y;\n    float _2938;\n    if (_2936 > 0.0f)\n    {\n        _2938 = _2936;\n    }\n    else\n    {\n        _2938 = 1.5f * _2886;\n    }\n    float4 _2958 = float4(world + (n * (_2938 * sqrt(1.0f - (_2891 * _2891)))), 1.0f);\n    float _2962 = dot(_2864, _2958);\n    float _2965 = _2874.y;\n    if (_2962 < _2965)\n    {\n        return 1.0f;\n    }\n    float2 _2980 = float2(dot(fa_light_texel(param_4), _2958), dot(fa_light_texel(param_5), _2958)) / _2962.xx;\n    float _2982 = _2980.x;\n    bool _2985 = _2982 < _2869.x;\n    bool _2994;\n    if (!_2985)\n    {\n        _2994 = _2982 > _2869.z;\n    }\n    else\n    {\n        _2994 = _2985;\n    }\n    bool _3003;\n    if (!_2994)\n    {\n        _3003 = _2980.y < _2869.y;\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    bool _3012;\n    if (!_3003)\n    {\n        _3012 = _2980.y > _2869.w;\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        return 1.0f;\n    }\n    float _3018 = _2806.x;\n    float _3020;\n    if (_3018 > 0.0f)\n    {\n        _3020 = _3018;\n    }\n    else\n    {\n        _3020 = 1.5f * _2886;\n    }\n    float2 param_9 = _2980;\n    float4 param_10 = _2869;\n    float param_11 = _2962 - (_3020 * (1.0f + (0.5f * _2933)));\n    float param_12 = _2886;\n    float param_13 = 1.0f;\n    float param_14 = _2874.z * 0.25f;\n    float param_15 = (_2886 * min(_2933, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2965, _2874.z);\n    int param_17 = int(_2801.z + 0.5f);\n    float param_18 = _2801.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5171 = _653_fa_ct_a.x < 0.5f;\n    bool _5178;\n    if (!_5171)\n    {\n        _5178 = _2315_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5178 = _5171;\n    }\n    if (_5178)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2315_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5191 = fa_light_texel(param);\n    float _5192 = _5191.y;\n    float len = _5192;\n    if (_5192 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5204 = length(world - _653_fa_camera_pos.xyz);\n    float _5214 = 1.0f - smoothstep(0.5f * _653_fa_ct_b.x, _653_fa_ct_b.x, _5204);\n    if (_5214 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5220 = len;\n    float _5223 = min(_5220, 0.89999997615814208984375f * dist);\n    len = _5223;\n    float _5228 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5204);\n    float _5233 = _5228 + (0.5f * _5223);\n    float3 _5239 = world + (gn * _5228);\n    float _5241 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5305;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5256 = (float(k) + _5241) * 0.083333335816860198974609375f;\n        float3 _5264 = _5239 + (l * (_5256 * len));\n        float4 _5270 = float4(_5264, 1.0f);\n        float _5276 = dot(_653_fa_ct_vpw, _5270);\n        if (_5276 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5296 = float2(dot(_653_fa_ct_vpx, _5270), dot(_653_fa_ct_vpy, _5270)) / _5276.xx;\n        float _5300 = _5296.x * 0.5f;\n        float _5301 = _5300 + 0.5f;\n        if (_653_fa_ct_a.y > 0.5f)\n        {\n            _5305 = (_5296.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5305 = 0.5f - (_5296.y * 0.5f);\n        }\n        bool _5321 = _5301 < 0.0f;\n        bool _5328;\n        if (!_5321)\n        {\n            _5328 = _5301 >= 1.0f;\n        }\n        else\n        {\n            _5328 = _5321;\n        }\n        bool _5335;\n        if (!_5328)\n        {\n            _5335 = _5305 < 0.0f;\n        }\n        else\n        {\n            _5335 = _5328;\n        }\n        bool _5342;\n        if (!_5335)\n        {\n            _5342 = _5305 >= 1.0f;\n        }\n        else\n        {\n            _5342 = _5335;\n        }\n        if (_5342)\n        {\n            break;\n        }\n        float4 _5369 = fa_screen_tex.Load(int3(clamp(int2(float2(_5301, _5305) * _653_fa_ct_a.zw), int2(0, 0), int2(_653_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5369.w < 0.5f)\n        {\n            continue;\n        }\n        float _5388 = (dot(_653_fa_ct_fwd.xyz, _5264) + _653_fa_ct_fwd.w) - _5369.x;\n        if ((_5388 > _5228) && (_5388 < _5233))\n        {\n            occ = max(occ, (1.0f - (_5256 * _5256)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5301, 0.5f - _5300), min(_5305, 1.0f - _5305))));\n        }\n    }\n    return 1.0f - (occ * _5214);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5854 = fa_baked_keep(param);\n    if (_5854 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9042 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9042;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5880 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9044 = _5880.color;\n    float _9045 = _5880.attenuation;\n    float _9046 = _5880.shadow;\n    bool _5883 = _5880.type == 0;\n    if (_5883 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5880.direction;\n        float _5894 = fa_shadow_factor(param_5, param_6);\n        _9046 = _5894;\n        _9044 *= _5894;\n    }\n    else\n    {\n        bool _5905 = _5880.type != 0;\n        bool _5911;\n        if (_5905)\n        {\n            _5911 = _9045 > 0.0f;\n        }\n        else\n        {\n            _5911 = _5905;\n        }\n        if (_5911)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5880.direction;\n            float _5930 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9046 = _5930;\n            _9044 *= _5930;\n        }\n    }\n    bool _5940 = _653_fa_ct_a.x > 0.5f;\n    bool _5946;\n    if (_5940)\n    {\n        _5946 = _9045 > 0.0f;\n    }\n    else\n    {\n        _5946 = _5940;\n    }\n    if (_5946)\n    {\n        float _5953;\n        if (_5883)\n        {\n            _5953 = 1000000000.0f;\n        }\n        else\n        {\n            _5953 = _5880._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5880.direction;\n        float param_18 = _5953;\n        float _5971 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9046 *= _5971;\n        _9044 *= _5971;\n    }\n    float _5984 = _9045;\n    float _5985 = _5984 * _5854;\n    _9045 = _5985;\n    float3 _5989 = _9044;\n    float3 _5990 = _5989 * _5854;\n    _9044 = _5990;\n    LightSample _9061 = { _5880.direction, _5990, _5985, _9046, _5880._distance, _5880.type };\n    return _9061;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6024 = v - (n * dot(v, n));\n    float3 t = _6024;\n    float _6028 = dot(_6024, _6024);\n    float l2 = _6028;\n    if (_6028 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6038;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6038 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6038 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6038;\n        l2 = dot(_6038, _6038);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6073 = dot(a, a);\n    float _6077 = dot(b, b);\n    if ((_6073 < 1.0000000195414813782625560981111e-24f) || (_6077 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6091 = a * rsqrt(_6073);\n    float3 _6096 = b * rsqrt(_6077);\n    float _6100 = dot(_6091, _6096);\n    float _6103 = abs(_6100);\n    float g = (((((((((((0.0416471660137176513671875f * _6103) - 0.1924748718738555908203125f) * _6103) + 0.4179156124591827392578125f) * _6103) - 0.616057217121124267578125f) * _6103) + 0.777722418308258056640625f) * _6103) - 0.999542415142059326171875f) * _6103) + 1.570791721343994140625f;\n    if (_6100 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6100 * _6100), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6091, _6096) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6160 = a.z > 0.0f;\n    bool _6164 = b.z > 0.0f;\n    if (_6160 && _6164)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6160 != _6164)\n        {\n            float3 _6199 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6199.z = 0.0f;\n            if (_6160)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6199;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6199;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6199;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6199;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6248 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6274 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6300 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6326 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6248;\n    float3 param_1 = _6274;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6274;\n    float3 param_7 = _6300;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6300;\n    float3 param_13 = _6326;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6326;\n    float3 param_19 = _6248;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6475 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6499 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6515 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6475;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6499;\n    float4 param_9 = m;\n    float3 param_10 = _6475;\n    float3 param_11 = _6499;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6515;\n    float4 param_14 = m;\n    float3 param_15 = _6475;\n    float3 param_16 = _6515;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6573 = fa_light_base(param);\n    int param_1 = _6573;\n    int param_2 = _6573 + 1;\n    int param_3 = _6573 + 2;\n    int param_4 = _6573 + 4;\n    float4 _6595 = fa_light_texel(param_4);\n    int param_5 = _6573 + 5;\n    float4 _6600 = fa_light_texel(param_5);\n    int param_6 = _6573 + 6;\n    float4 _6605 = fa_light_texel(param_6);\n    float _6606 = _6605.w;\n    float3 _6611 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6613 = _6606 < 1.5f;\n    bool _6620;\n    if (_6613)\n    {\n        _6620 = dot(normalize(fa_light_texel(param_3).xyz), _6611) >= 0.0f;\n    }\n    else\n    {\n        _6620 = _6613;\n    }\n    if (_6620)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6629 = (_6606 > 0.5f) && _6613;\n    float _6633 = _6629 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6636 = _6595.xyz;\n    float _6638 = _6595.w;\n    float3 _6644 = _6600.xyz;\n    float _6646 = _6600.w;\n    float3 up = _6644 * (_6646 * _6633);\n    float _6652;\n    if (_6629)\n    {\n        _6652 = (3.1415927410125732421875f * _6638) * _6638;\n    }\n    else\n    {\n        _6652 = (4.0f * _6638) * _6646;\n    }\n    if (_6606 > 1.5f)\n    {\n        float3 _6678 = cross(_6636, -_6611);\n        float3 perp = _6678;\n        float _6682 = dot(_6678, _6678);\n        float3 _6685;\n        if (_6682 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6685 = perp * rsqrt(_6682);\n        }\n        else\n        {\n            _6685 = _6644;\n        }\n        perp = _6685;\n        up = _6685 * _6646;\n    }\n    float _6706 = max(_6652, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6716 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6716;\n    float3 param_10 = n;\n    float3 param_11 = _6611;\n    float3 _6724 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6716;\n    float3 param_13 = n;\n    float3 param_14 = _6636 * (_6638 * _6633);\n    float3 _6732 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6716;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6740 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6606;\n    float3 param_20 = _6724;\n    float3 param_21 = _6732;\n    float3 param_22 = _6740;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6759 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6759;\n    float2 param_26 = _6759 + float2(64.0f, 0.0f);\n    float4 _6769 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6606;\n    float3 param_29 = _6724;\n    float3 param_30 = _6732;\n    float3 param_31 = _6740;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6769.x) + ((f90.xxx - f0) * _6769.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6611, _6611)) + _6706) / _6706) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4908 = 1.0f / alpha;\n    return ((2.0f + _4908) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4908)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4943 = max(dot(L.nc, l), 0.0f);\n    float _4949 = max(dot(L.nc, h), 0.0f);\n    float _4958 = ((_4949 * _4949) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4958) * _4958)) * (0.5f / max(lerp((2.0f * _4943) * L.coat_ndv, _4943 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4943)) * _4943;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6837;\n    if (L.sheen_on)\n    {\n        _6837 = L.sheen_scale;\n    }\n    else\n    {\n        _6837 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6837);\n    float3 _6850 = normalize(l + v);\n    int param_10 = li;\n    float3 _6861 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6870 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6850), 0.0f);\n        float param_13 = _6870;\n        float param_14 = ndv;\n        result += ((L.sheen * _6861) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6870)) * _6870) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6850;\n        float param_18 = max(dot(v, _6850), 0.0f);\n        result += (_6861 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4811 = tdh / at;\n    float _4815 = bdh / ab;\n    float _4827 = ((_4811 * _4811) + (_4815 * _4815)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4827) * _4827);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5007 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5086 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5086) * _5086);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5007);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5007));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4210 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4213 = _4210.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4213 * _4213, exp2((-9.27999973297119140625f) * ndv)) * _4213) + _4210.y)) + _4210.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3518;\n    if (lv == 0)\n    {\n        _3518 = 0.0f;\n    }\n    else\n    {\n        _3518 = res + 2.0f;\n    }\n    float _3528;\n    if (lv == 0)\n    {\n        _3528 = 0.0f;\n    }\n    else\n    {\n        _3528 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3518, _3528)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3574;\n    if (res > 64.5f)\n    {\n        _3574 = 5.0f;\n    }\n    else\n    {\n        _3574 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3589 = clamp(rough, 0.0f, 1.0f) * (_3574 - 1.0f);\n    int _3596 = int(min(floor(_3589), _3574 - 2.0f));\n    float _3601 = _3589 - float(_3596);\n    float3 param = d;\n    float2 _3605 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3596;\n    float2 param_4 = _3605;\n    float3 _3615 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3601 < 0.00200000009499490261077880859375f)\n    {\n        return _3615;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3596 + 1;\n    float2 param_8 = _3605;\n    return lerp(_3615, fa_probe_level(param_5, param_6, param_7, param_8), _3601.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3688 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3695 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3702 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3708 = dot(bx.xyz, d);\n    float _3712 = dot(by.xyz, d);\n    float _3716 = dot(bz.xyz, d);\n    float _3722;\n    if (_3708 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3722 = (1.0f - _3688) / _3708;\n    }\n    else\n    {\n        float _3736;\n        if (_3708 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3736 = ((-1.0f) - _3688) / _3708;\n        }\n        else\n        {\n            _3736 = 1000000015047466219876688855040.0f;\n        }\n        _3722 = _3736;\n    }\n    float tx = _3722;\n    float _3753;\n    if (_3712 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3753 = (1.0f - _3695) / _3712;\n    }\n    else\n    {\n        float _3766;\n        if (_3712 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3766 = ((-1.0f) - _3695) / _3712;\n        }\n        else\n        {\n            _3766 = 1000000015047466219876688855040.0f;\n        }\n        _3753 = _3766;\n    }\n    float ty = _3753;\n    float _3782;\n    if (_3716 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3782 = (1.0f - _3702) / _3716;\n    }\n    else\n    {\n        float _3795;\n        if (_3716 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3795 = ((-1.0f) - _3702) / _3716;\n        }\n        else\n        {\n            _3795 = 1000000015047466219876688855040.0f;\n        }\n        _3782 = _3795;\n    }\n    float _3807 = tx;\n    float _3810 = (_3807 > 0.0f) ? _3807 : 1000000015047466219876688855040.0f;\n    tx = _3810;\n    float _3811 = ty;\n    float _3814 = (_3811 > 0.0f) ? _3811 : 1000000015047466219876688855040.0f;\n    ty = _3814;\n    float _3824 = min(_3810, min(_3814, (_3782 > 0.0f) ? _3782 : 1000000015047466219876688855040.0f));\n    if (_3824 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3840 = (fa_world_pos + (d * _3824)) - posw.xyz;\n    float3 _3845;\n    if (dot(_3840, _3840) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3845 = normalize(_3840);\n    }\n    else\n    {\n        _3845 = d;\n    }\n    return _3845;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3891 = (1.0f - _653_fa_rpa_tile.w) - _653_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3891 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_653_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _653_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3919 = rough * rough;\n            float _3950 = 0.60000002384185791015625f * _3919;\n            base = lerp(lerp(_653_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_653_fa_env_horizon.xyz, _653_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3919)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3950, 0.0500000007450580596923828125f + _3950, d.y).xxx), ((_653_fa_env_sky.xyz + _653_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3919 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3891;\n    }\n    if (_653_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _653_fa_rpa_tile;\n        float4 param_5 = _653_fa_rpa_pos;\n        float4 param_6 = _653_fa_rpa_bx;\n        float4 param_7 = _653_fa_rpa_by;\n        float4 param_8 = _653_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4009 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4009 * _653_fa_rpa_tile.w);\n    }\n    if (_653_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _653_fa_rpb_tile;\n        float4 param_12 = _653_fa_rpb_pos;\n        float4 param_13 = _653_fa_rpb_bx;\n        float4 param_14 = _653_fa_rpb_by;\n        float4 param_15 = _653_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4041 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4041 * _653_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4688;\n        if (L.aniso >= 0.0f)\n        {\n            _4688 = L.b;\n        }\n        else\n        {\n            _4688 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4688, v), _4688), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4724 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4724.x) + (L.f90.xxx * _4724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4782 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4782.x) + _4782.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4252 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4252.x) + _4252.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_653_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_653_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5492 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5496 = fa_xm_origin(param_1);\n    float2 _5502 = (uv * _5492) - 0.5f.xx;\n    float2 _5505 = frac(_5502);\n    float2 _5508 = floor(_5502);\n    float2 param_2 = _5492;\n    float2 param_3 = _5496;\n    float2 param_4 = _5508;\n    float2 param_5 = _5492;\n    float2 param_6 = _5496;\n    float2 param_7 = _5508 + float2(1.0f, 0.0f);\n    float2 param_8 = _5492;\n    float2 param_9 = _5496;\n    float2 param_10 = _5508 + float2(0.0f, 1.0f);\n    float2 param_11 = _5492;\n    float2 param_12 = _5496;\n    float2 param_13 = _5508 + 1.0f.xx;\n    float3 _5550 = _5505.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5550), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5550), _5505.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5569 = max(_653_fa_tr_b.w - 1.0f, 0.0f);\n    float _5573 = clamp(lod, 0.0f, _5569);\n    int _5577 = int(floor(_5573));\n    int param = _5577;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5587 = float(_5577);\n    float _5588 = _5573 - _5587;\n    bool _5590 = _5588 > 0.001000000047497451305389404296875f;\n    bool _5597;\n    if (_5590)\n    {\n        _5597 = _5587 < _5569;\n    }\n    else\n    {\n        _5597 = _5590;\n    }\n    if (_5597)\n    {\n        int param_2 = _5577 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5588.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5623 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _5623.x) + (f90.xxx * _5623.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _5651 = max(s.thickness, 0.0f);\n    bool _5656 = _5651 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5656)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5651);\n    }\n    bool _5681 = _653_fa_tr_a.w > 1.5f;\n    bool _5688;\n    if (!_5681)\n    {\n        _5688 = _653_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5688 = _5681;\n    }\n    if (_5688)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_5656)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5651);\n    }\n    float4 _5723 = float4(world, 1.0f);\n    float _5728 = dot(_653_fa_ct_vpw, _5723);\n    float2 uv = 0.5f.xx;\n    if (_5728 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5746 = float2(dot(_653_fa_ct_vpx, _5723), dot(_653_fa_ct_vpy, _5723)) / _5728.xx;\n        float _5754;\n        if (_653_fa_ct_a.y > 0.5f)\n        {\n            _5754 = (_5746.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5754 = 0.5f - (_5746.y * 0.5f);\n        }\n        uv = float2((_5746.x * 0.5f) + 0.5f, _5754);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_653_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2315_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3269 = int(_2315_fa_shadow_cfg.x + 0.5f);\n    float _3279 = dot(world - _2315_fa_shadow_eye.xyz, _2315_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3284 = _3269 > 0;\n    bool _3293;\n    if (_3284)\n    {\n        int param = _3269 - 1;\n        _3293 = _3279 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3293 = _3284;\n    }\n    if (_3293)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3299 = _3269 > 1;\n        bool _3306;\n        if (_3299)\n        {\n            _3306 = _3279 > _2315_fa_shadow_split.x;\n        }\n        else\n        {\n            _3306 = _3299;\n        }\n        if (_3306)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3312 = _3269 > 2;\n        bool _3319;\n        if (_3312)\n        {\n            _3319 = _3279 > _2315_fa_shadow_split.y;\n        }\n        else\n        {\n            _3319 = _3312;\n        }\n        if (_3319)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3325 = _3269 > 3;\n        bool _3332;\n        if (_3325)\n        {\n            _3332 = _3279 > _2315_fa_shadow_split.z;\n        }\n        else\n        {\n            _3332 = _3325;\n        }\n        if (_3332)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _8703 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8703 = -_8703;\n    }\n    float3 _7986 = normalize(_653_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _8716 = { fa_world_pos, _8703, fa_world_tangent, fa_uv, fa_vertex_color, _7986, gl_FrontFacing };\n    SurfaceInput param_1 = _8716;\n    Surface _7994 = fa_standard_surface(param_1);\n    float3 _8734 = _7994.albedo;\n    float _8735 = _7994.alpha;\n    float3 _8736 = _7994.normal;\n    float _8737 = _7994.metallic;\n    float _8738 = _7994.roughness;\n    float _8739 = _7994.occlusion;\n    float3 _8740 = _7994.emission;\n    float _8741 = _7994.clearcoat;\n    float _8742 = _7994.clearcoat_roughness;\n    float3 _8743 = _7994.sheen_color;\n    float _8744 = _7994.sheen_roughness;\n    float _8745 = _7994.anisotropy;\n    float _8746 = _7994.anisotropy_rotation;\n    float _8747 = _7994.specular;\n    float _8748 = _7994.ior;\n    float3 _8749 = _7994.specular_color;\n    float _8750 = _7994.transmission;\n    float _8751 = _7994.thickness;\n    float3 _8752 = _7994.attenuation_color;\n    float _8753 = _7994.attenuation_distance;\n    SurfaceInput _8724 = { fa_world_pos, _8703, fa_world_tangent, fa_uv, fa_vertex_color, _7986, gl_FrontFacing };\n    SurfaceInput param_2 = _8724;\n    Surface param_3 = _7994;\n    surface(param_2, param_3);\n    _8734 = param_3.albedo;\n    _8735 = param_3.alpha;\n    _8736 = param_3.normal;\n    _8737 = param_3.metallic;\n    _8738 = param_3.roughness;\n    _8739 = param_3.occlusion;\n    _8740 = param_3.emission;\n    _8741 = param_3.clearcoat;\n    _8742 = param_3.clearcoat_roughness;\n    _8743 = param_3.sheen_color;\n    _8744 = param_3.sheen_roughness;\n    _8745 = param_3.anisotropy;\n    _8746 = param_3.anisotropy_rotation;\n    _8747 = param_3.specular;\n    _8748 = param_3.ior;\n    _8749 = param_3.specular_color;\n    _8750 = param_3.transmission;\n    _8751 = param_3.thickness;\n    _8752 = param_3.attenuation_color;\n    _8753 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _8703;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8734 = param_6;\n    _8736 = param_7;\n    if (_8735 < _8022_alphaCutoff)\n    {\n        discard;\n    }\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_653_fa_emissive.w > 0.5f)\n    {\n        result = _8734;\n    }\n    else\n    {\n        float3 _8045 = normalize(_8736);\n        float _8052 = clamp(_8737, 0.0f, 1.0f);\n        float _8056 = clamp(_8738, 0.0500000007450580596923828125f, 1.0f);\n        float _8060 = _8056 * _8056;\n        float _8064 = _8060 * _8060;\n        float _8069 = max(dot(_8045, _7986), 9.9999997473787516355514526367188e-05f);\n        float _8075 = 1.0f - _8052;\n        float _8076 = clamp(_8750, 0.0f, 1.0f) * _8075;\n        float3 _8085 = (_8734 * _8075) * (1.0f - _8076);\n        float3 _8092 = lerp(0.039999999105930328369140625f.xxx, _8734, _8052.xxx);\n        float3 f0 = _8092;\n        SurfaceInput _8732 = { fa_world_pos, _8703, fa_world_tangent, fa_uv, fa_vertex_color, _7986, gl_FrontFacing };\n        SurfaceInput param_8 = _8732;\n        Surface _8835 = { _8734, _8735, _8736, _8737, _8738, _8739, _8740, _8741, _8742, _8743, _8744, _8745, _8746, _8747, _8748, _8749, _8750, _8751, _8752, _8753 };\n        Surface param_9 = _8835;\n        float3 param_10 = _8045;\n        float3 param_11 = _7986;\n        float param_12 = _8052;\n        float param_13 = _8056;\n        float3 param_14 = _8092;\n        FaLayers _8108 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8045;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8085) * _8739;\n        if (_8108.on)\n        {\n            lit *= _8108.base_scale;\n        }\n        int _8130 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8130; ln++)\n        {\n            int param_16 = ln;\n            int _8143 = fa_cl_light(param_16);\n            int param_17 = _8143;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8143;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _8703;\n            LightSample _8159 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8167 = max(dot(_8045, _8159.direction), 0.0f);\n            float _8173 = _8159.attenuation * _8159.shadow;\n            float3 _8178 = normalize(_8159.direction + _7986);\n            float _8183 = max(dot(_8045, _8178), 0.0f);\n            float _8188 = max(dot(_7986, _8178), 0.0f);\n            bool _8195;\n            if (fa_light_is_area)\n            {\n                _8195 = !_8108.on;\n            }\n            else\n            {\n                _8195 = fa_light_is_area;\n            }\n            if (_8195)\n            {\n                int param_21 = _8143;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8045;\n                float3 param_24 = _7986;\n                float3 param_25 = _8085;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _8056;\n                float param_29 = _8069;\n                float param_30 = _8173;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8108;\n                    int param_32 = _8143;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _8045;\n                    float3 param_35 = _7986;\n                    float3 param_36 = _8159.direction;\n                    float3 param_37 = _8085;\n                    float3 param_38 = f0;\n                    float param_39 = _8056;\n                    float param_40 = _8069;\n                    float param_41 = _8173;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8108.on)\n                    {\n                        FaLayers param_42 = _8108;\n                        float3 param_43 = _8085;\n                        float3 param_44 = f0;\n                        float3 param_45 = _8045;\n                        float3 param_46 = _7986;\n                        float3 param_47 = _8159.direction;\n                        float3 param_48 = _8178;\n                        float param_49 = _8167;\n                        float param_50 = _8069;\n                        float param_51 = _8183;\n                        float param_52 = _8188;\n                        float param_53 = _8060;\n                        float param_54 = _8064;\n                        int param_55 = _8143;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8173));\n                    }\n                    else\n                    {\n                        float _8301 = ((_8183 * _8183) * (_8064 - 1.0f)) + 1.0f;\n                        int param_56 = _8143;\n                        lit += (((_8085 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8188, 5.0f))) * (((_8064 / ((3.1415927410125732421875f * _8301) * _8301)) * (0.5f / max(lerp((2.0f * _8167) * _8069, _8167 + _8069, _8060), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8167))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8167 * _8173));\n                    }\n                }\n            }\n        }\n        if (_8108.on)\n        {\n            FaLayers param_57 = _8108;\n            float3 param_58 = _8045;\n            float3 param_59 = _7986;\n            float3 param_60 = f0;\n            float param_61 = _8056;\n            float param_62 = _8739;\n            lit += fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, param_62);\n        }\n        else\n        {\n            float3 param_63 = _8045;\n            float3 param_64 = _7986;\n            float3 param_65 = f0;\n            float param_66 = _8056;\n            lit += (fa_sky_reflection(param_63, param_64, param_65, param_66) * _8739);\n        }\n        if (_8076 > 0.0f)\n        {\n            float _8399;\n            if (_8108.on)\n            {\n                _8399 = _8108.f90;\n            }\n            else\n            {\n                _8399 = 1.0f;\n            }\n            float _8407;\n            if (_8108.on)\n            {\n                _8407 = _8108.base_scale;\n            }\n            else\n            {\n                _8407 = 1.0f;\n            }\n            Surface _8856 = { _8734, _8735, _8736, _8737, _8738, _8739, _8740, _8741, _8742, _8743, _8744, _8745, _8746, _8747, _8748, _8749, _8750, _8751, _8752, _8753 };\n            Surface param_67 = _8856;\n            float3 param_68 = _8045;\n            float3 param_69 = _7986;\n            float param_70 = _8056;\n            float3 param_71 = f0;\n            float param_72 = _8399;\n            float param_73 = _8407;\n            float param_74 = _8076;\n            float param_75 = fa_tr_blend;\n            float3 _8431 = fa_transmitted(param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75);\n            fa_tr_blend = param_75;\n            lit += _8431;\n        }\n        result = lit;\n    }\n    float3 _8438 = result;\n    float3 _8439 = _8438 + _8740;\n    result = _8439;\n    float3 param_76 = _8439;\n    float3 param_77 = fa_world_pos;\n    result = fa_shadow_debug(param_76, param_77);\n    bool _8448 = _653_fa_fog.w > 0.0f;\n    bool _8455;\n    if (!_8448)\n    {\n        _8455 = _653_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8455 = _8448;\n    }\n    if (_8455)\n    {\n        float3 _8464 = fa_world_pos - _653_fa_camera_pos.xyz;\n        float _8470 = dot(_8464, _653_fa_fog_c.xyz);\n        bool _8474 = _653_fa_fog_c.w > 0.5f;\n        float _8475;\n        if (_8474)\n        {\n            _8475 = _8470;\n        }\n        else\n        {\n            _8475 = length(_8464);\n        }\n        float _8487 = _8475 - _653_fa_fog_b.x;\n        if (_8487 > 0.0f)\n        {\n            float _8496 = _653_fa_fog.w * _8487;\n            float tau = _8496 * _8496;\n            if (_653_fa_fog_b.y > 0.0f)\n            {\n                float _8512;\n                if (_8474)\n                {\n                    _8512 = fa_world_pos.y - (_653_fa_fog_c.y * _8470);\n                }\n                else\n                {\n                    _8512 = _653_fa_camera_pos.y;\n                }\n                float _8533 = lerp(_8512, fa_world_pos.y, clamp(_653_fa_fog_b.x / _8475, 0.0f, 1.0f));\n                float _8537 = fa_world_pos.y - _8533;\n                float _8542 = _8533 - _653_fa_fog_b.z;\n                float _8547 = fa_world_pos.y - _653_fa_fog_b.z;\n                bool _8550 = _8542 <= 0.0f;\n                bool _8551 = !_8550;\n                bool _8557;\n                if (_8551)\n                {\n                    _8557 = _653_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8557 = _8550;\n                }\n                float _8558;\n                if (_8557)\n                {\n                    _8558 = _653_fa_fog_b.y;\n                }\n                else\n                {\n                    _8558 = _653_fa_fog_b.y * exp(-min(_653_fa_fog_b.w * _8542, 80.0f));\n                }\n                bool _8585;\n                if (_8551)\n                {\n                    _8585 = _653_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8585 = _8550;\n                }\n                float _8586;\n                if (_8585)\n                {\n                    _8586 = _653_fa_fog_b.y * _8542;\n                }\n                else\n                {\n                    _8586 = (_653_fa_fog_b.y * (1.0f - exp(-min(_653_fa_fog_b.w * _8542, 80.0f)))) / _653_fa_fog_b.w;\n                }\n                bool _8611 = _8547 <= 0.0f;\n                bool _8618;\n                if (!_8611)\n                {\n                    _8618 = _653_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8618 = _8611;\n                }\n                float _8619;\n                if (_8618)\n                {\n                    _8619 = _653_fa_fog_b.y * _8547;\n                }\n                else\n                {\n                    _8619 = (_653_fa_fog_b.y * (1.0f - exp(-min(_653_fa_fog_b.w * _8547, 80.0f)))) / _653_fa_fog_b.w;\n                }\n                float _8646;\n                if (abs(_8537) < 0.001000000047497451305389404296875f)\n                {\n                    _8646 = _8558;\n                }\n                else\n                {\n                    _8646 = (_8619 - _8586) / _8537;\n                }\n                tau += (_8487 * max(_8646, 0.0f));\n            }\n            result = lerp(result, _653_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _8682 = 1.0f - fa_tr_blend;\n        result /= _8682.xxx;\n        _8735 *= _8682;\n    }\n    fa_frag_color = float4(result, _8735);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_653",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2315",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8022",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _301 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _301;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0f);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n    float4 _227_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _800 = base_t;\n    _800.x = _239.x;\n    _800.y = _239.y;\n    _800.z = _239.z;\n    base_t = _800;\n    float4 _255 = (_800 * _227_fa_base_color) * i.vertex_color;\n    float3 _755 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _808 = _292;\n        _808.x = _297.x;\n        _808.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _808;\n        _755 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _811 = mrt;\n    _811.x = _326.x;\n    _811.y = _326.y;\n    _811.z = _326.z;\n    mrt = _811;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _760 = _227_fa_layers_a.x;\n    float _761 = _227_fa_layers_a.y;\n    float _764 = _227_fa_layers_a.z;\n    float _763 = _227_fa_layers_b.w;\n    float _766 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _760 *= _368.y;\n            _761 *= _368.z;\n            _763 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _764 *= mrt.x;\n            _766 *= mrt.w;\n        }\n    }\n    Surface _793 = { _255.xyz, _255.w, _755, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _760, _761, _227_fa_layers_b.xyz, _763, _764, _227_fa_layers_a.w, _766, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _793;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _650 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _650 = -_650;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _663 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _663;\n    Surface _556 = fa_standard_surface(param);\n    float3 _674 = _556.normal;\n    SurfaceInput _671 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _671;\n    Surface param_2 = _556;\n    surface(param_1, param_2);\n    _674 = param_2.normal;\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _577 = normalize(_674);\n    float3 _592 = normalize(float3(dot(fa_pre_r0, _577), dot(fa_pre_r1, _577), dot(fa_pre_r2, _577)));\n    float _604 = _592.z;\n    float2 e = _592.xy / ((abs(_592.x) + abs(_592.y)) + abs(_604)).xx;\n    if (_604 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_567",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0f);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n    float4 _227_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _800 = base_t;\n    _800.x = _239.x;\n    _800.y = _239.y;\n    _800.z = _239.z;\n    base_t = _800;\n    float4 _255 = (_800 * _227_fa_base_color) * i.vertex_color;\n    float3 _755 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _808 = _292;\n        _808.x = _297.x;\n        _808.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _808;\n        _755 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _811 = mrt;\n    _811.x = _326.x;\n    _811.y = _326.y;\n    _811.z = _326.z;\n    mrt = _811;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _760 = _227_fa_layers_a.x;\n    float _761 = _227_fa_layers_a.y;\n    float _764 = _227_fa_layers_a.z;\n    float _763 = _227_fa_layers_b.w;\n    float _766 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _760 *= _368.y;\n            _761 *= _368.z;\n            _763 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _764 *= mrt.x;\n            _766 *= mrt.w;\n        }\n    }\n    Surface _793 = { _255.xyz, _255.w, _755, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _760, _761, _227_fa_layers_b.xyz, _763, _764, _227_fa_layers_a.w, _766, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _793;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _650 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _650 = -_650;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _663 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _663;\n    Surface _556 = fa_standard_surface(param);\n    float3 _674 = _556.normal;\n    SurfaceInput _671 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _671;\n    Surface param_2 = _556;\n    surface(param_1, param_2);\n    _674 = param_2.normal;\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _577 = normalize(_674);\n    float3 _592 = normalize(float3(dot(fa_pre_r0, _577), dot(fa_pre_r1, _577), dot(fa_pre_r2, _577)));\n    float _604 = _592.z;\n    float2 e = _592.xy / ((abs(_592.x) + abs(_592.y)) + abs(_604)).xx;\n    if (_604 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_567",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n    float4 _122_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _256 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _256;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_239, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n    float4 _227_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _734 = base_t;\n    _734.x = _239.x;\n    _734.y = _239.y;\n    _734.z = _239.z;\n    base_t = _734;\n    float4 _255 = (_734 * _227_fa_base_color) * i.vertex_color;\n    float3 _695 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _742 = _292;\n        _742.x = _297.x;\n        _742.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _742;\n        _695 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _745 = mrt;\n    _745.x = _326.x;\n    _745.y = _326.y;\n    _745.z = _326.z;\n    mrt = _745;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _700 = _227_fa_layers_a.x;\n    float _701 = _227_fa_layers_a.y;\n    float _704 = _227_fa_layers_a.z;\n    float _703 = _227_fa_layers_b.w;\n    float _706 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _700 *= _368.y;\n            _701 *= _368.z;\n            _703 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _704 *= mrt.x;\n            _706 *= mrt.w;\n        }\n    }\n    Surface _733 = { _255.xyz, _255.w, _695, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _700, _701, _227_fa_layers_b.xyz, _703, _704, _227_fa_layers_a.w, _706, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _733;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _590 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _590 = -_590;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _603 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _603;\n    SurfaceInput _611 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _611;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_567",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n    float4 _127_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _377 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _377;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _360 = _311.world_pos;\n    fa_world_pos = _360;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_360, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n    float4 _227_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _734 = base_t;\n    _734.x = _239.x;\n    _734.y = _239.y;\n    _734.z = _239.z;\n    base_t = _734;\n    float4 _255 = (_734 * _227_fa_base_color) * i.vertex_color;\n    float3 _695 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _742 = _292;\n        _742.x = _297.x;\n        _742.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _742;\n        _695 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _745 = mrt;\n    _745.x = _326.x;\n    _745.y = _326.y;\n    _745.z = _326.z;\n    mrt = _745;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _700 = _227_fa_layers_a.x;\n    float _701 = _227_fa_layers_a.y;\n    float _704 = _227_fa_layers_a.z;\n    float _703 = _227_fa_layers_b.w;\n    float _706 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _700 *= _368.y;\n            _701 *= _368.z;\n            _703 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _704 *= mrt.x;\n            _706 *= mrt.w;\n        }\n    }\n    Surface _733 = { _255.xyz, _255.w, _695, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _700, _701, _227_fa_layers_b.xyz, _703, _704, _227_fa_layers_a.w, _706, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _733;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _590 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _590 = -_590;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _603 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _603;\n    SurfaceInput _611 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _611;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_567",
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
