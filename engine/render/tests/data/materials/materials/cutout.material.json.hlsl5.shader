{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4850[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _612_fa_camera_pos : packoffset(c0);\n    float4 _612_fa_ambient : packoffset(c1);\n    float4 _612_fa_base_color : packoffset(c2);\n    float4 _612_fa_emissive : packoffset(c3);\n    float4 _612_fa_model_emissive : packoffset(c4);\n    float4 _612_fa_pbr : packoffset(c5);\n    float4 _612_fa_maps : packoffset(c6);\n    float4 _612_fa_fog : packoffset(c7);\n    float4 _612_fa_fog_b : packoffset(c8);\n    float4 _612_fa_fog_c : packoffset(c9);\n    float4 _612_fa_counts : packoffset(c10);\n    float4 _612_fa_env_sky : packoffset(c11);\n    float4 _612_fa_env_horizon : packoffset(c12);\n    float4 _612_fa_time : packoffset(c13);\n    float4 _612_fa_cl_vpx : packoffset(c14);\n    float4 _612_fa_cl_vpy : packoffset(c15);\n    float4 _612_fa_cl_vpw : packoffset(c16);\n    float4 _612_fa_cl_fwd : packoffset(c17);\n    float4 _612_fa_cl_grid : packoffset(c18);\n    float4 _612_fa_cl_info : packoffset(c19);\n    float4 _612_fa_layers_a : packoffset(c20);\n    float4 _612_fa_layers_b : packoffset(c21);\n    float4 _612_fa_layers_c : packoffset(c22);\n    float4 _612_fa_layers_d : packoffset(c23);\n    float4 _612_fa_ct_a : packoffset(c24);\n    float4 _612_fa_ct_b : packoffset(c25);\n    float4 _612_fa_ct_vpx : packoffset(c26);\n    float4 _612_fa_ct_vpy : packoffset(c27);\n    float4 _612_fa_ct_vpw : packoffset(c28);\n    float4 _612_fa_ct_fwd : packoffset(c29);\n    float4 _612_fa_tr_a : packoffset(c30);\n    float4 _612_fa_tr_b : packoffset(c31);\n    float4 _612_fa_probe_sh[9] : packoffset(c32);\n    float4 _612_fa_atlas : packoffset(c41);\n    float4 _612_fa_rpa_tile : packoffset(c42);\n    float4 _612_fa_rpa_pos : packoffset(c43);\n    float4 _612_fa_rpa_bx : packoffset(c44);\n    float4 _612_fa_rpa_by : packoffset(c45);\n    float4 _612_fa_rpa_bz : packoffset(c46);\n    float4 _612_fa_rpb_tile : packoffset(c47);\n    float4 _612_fa_rpb_pos : packoffset(c48);\n    float4 _612_fa_rpb_bx : packoffset(c49);\n    float4 _612_fa_rpb_by : packoffset(c50);\n    float4 _612_fa_rpb_bz : packoffset(c51);\n    float4 _612_fa_gi : packoffset(c52);\n    float4 _612_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2355_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2355_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2355_fa_shadow_info[4] : packoffset(c20);\n    float4 _2355_fa_shadow_split : packoffset(c24);\n    float4 _2355_fa_shadow_cfg : packoffset(c25);\n    float4 _2355_fa_shadow_bias : packoffset(c26);\n    float4 _2355_fa_shadow_eye : packoffset(c27);\n    float4 _2355_fa_shadow_fwd : packoffset(c28);\n    float4 _2355_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8816_alphaCutoff : packoffset(c0);\n    float _8816_fa_pad0 : packoffset(c0.y);\n    float _8816_fa_pad1 : packoffset(c0.z);\n    float _8816_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1637 = _612_fa_cl_info.x < 0.0f;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = _612_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    bool _1652;\n    if (!_1644)\n    {\n        _1652 = _612_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1652 = _1644;\n    }\n    bool _1659;\n    if (!_1652)\n    {\n        _1659 = _612_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1659 = _1652;\n    }\n    bool _1666;\n    if (!_1659)\n    {\n        _1666 = _612_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1666 = _1659;\n    }\n    if (_1666)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1676 = float4(world_pos, 1.0f);\n    float _1682 = dot(_612_fa_cl_vpw, _1676);\n    if (!(_1682 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1704 = float2(dot(_612_fa_cl_vpx, _1676), dot(_612_fa_cl_vpy, _1676)) / _1682.xx;\n    int _1708 = int(_612_fa_cl_grid.x);\n    int _1712 = int(_612_fa_cl_grid.y);\n    int param = (int(_612_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_612_fa_cl_fwd.xyz, world_pos) + _612_fa_cl_fwd.w, _612_fa_cl_grid.w) / _612_fa_cl_grid.w) * _612_fa_cl_grid.z)), 0, int(_612_fa_cl_info.y) - 1) * _1712) + clamp(int(floor(((_1704.y * 0.5f) + 0.5f) * _612_fa_cl_grid.y)), 0, _1712 - 1)) * _1708)) + clamp(int(floor(((_1704.x * 0.5f) + 0.5f) * _612_fa_cl_grid.x)), 0, _1708 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1788 = fa_cluster_texel(param);\n    return int2(int(_1788.x), int(_1788.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _6484 = dot(_612_fa_ct_fwd.xyz, world_pos) + _612_fa_ct_fwd.w;\n    float _6487 = fwidth(_6484);\n    bool _6490 = _612_fa_ct_b.y > 0.5f;\n    bool _6497;\n    if (!_6490)\n    {\n        _6497 = _612_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _6497 = _6490;\n    }\n    if (_6497)\n    {\n        fa_rt_slope = min(1.5f * _6487, 0.100000001490116119384765625f * _6484);\n    }\n    fa_cl_ndir = int(_612_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6513 = fa_cluster_lookup(param);\n    fa_cl_slot = _6513.x;\n    fa_cl_local = _6513.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7683 = fa_linear_to_srgb(param);\n        c = _7683;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7691 = fa_srgb_to_linear(param_1);\n            c = _7691;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _544;\n    if (i.front_facing)\n    {\n        _544 = i.world_normal;\n    }\n    else\n    {\n        _544 = -i.world_normal;\n    }\n    float3 _568 = normalize(i.world_tangent.xyz - (_544 * dot(_544, i.world_tangent.xyz)));\n    float3 _595 = normalize(((_568 * m.x) + ((cross(_544, _568) * i.world_tangent.w) * m.y)) + (_544 * m.z));\n    float3 _598;\n    if (i.front_facing)\n    {\n        _598 = _595;\n    }\n    else\n    {\n        _598 = -_595;\n    }\n    return _598;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w);\n    float param = _612_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7723 = fa_tex_fix(param_2, param_3);\n    float4 _10105 = base_t;\n    _10105.x = _7723.x;\n    _10105.y = _7723.y;\n    _10105.z = _7723.z;\n    base_t = _10105;\n    float4 _7737 = (_10105 * _612_fa_base_color) * i.vertex_color;\n    float3 _9855 = i.world_normal;\n    if (_612_fa_maps.z > 0.5f)\n    {\n        float param_4 = _612_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7771 = fa_tex_fix(param_6, param_7);\n        float3 _7774 = (_7771 * 2.0f) - 1.0f.xxx;\n        float2 _7779 = _7774.xy * _612_fa_maps.x;\n        float3 _10113 = _7774;\n        _10113.x = _7779.x;\n        _10113.y = _7779.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _10113;\n        _9855 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w);\n    float param_10 = _612_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7809 = fa_tex_fix(param_12, param_13);\n    float4 _10116 = mrt;\n    _10116.x = _7809.x;\n    _10116.y = _7809.y;\n    _10116.z = _7809.z;\n    mrt = _10116;\n    float4 _7839 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w);\n    float param_14 = _612_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7839.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7850 = fa_tex_fix(param_16, param_17);\n    float param_18 = _612_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7882 = fa_tex_fix(param_20, param_21);\n    float _9860 = _612_fa_layers_a.x;\n    float _9861 = _612_fa_layers_a.y;\n    float _9864 = _612_fa_layers_a.z;\n    float _9863 = _612_fa_layers_b.w;\n    float _9866 = _612_fa_layers_c.x;\n    if (_612_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_612_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9860 *= _7850.y;\n            _9861 *= _7850.z;\n            _9863 *= _7839.w;\n        }\n        if (_612_fa_layers_c.z > 1.5f)\n        {\n            _9864 *= mrt.x;\n            _9866 *= mrt.w;\n        }\n    }\n    Surface _9893 = { _7737.xyz, _7737.w, _9855, clamp(_612_fa_pbr.x * _7809.z, 0.0f, 1.0f), clamp(_612_fa_pbr.y * _7809.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_612_fa_maps.y * (_7850.x - 1.0f)), _612_fa_emissive.xyz + (_612_fa_model_emissive.xyz * _7882), _9860, _9861, _612_fa_layers_b.xyz, _9863, _9864, _612_fa_layers_a.w, _9866, _612_fa_layers_c.y, _612_fa_layers_d.xyz, _612_fa_tr_a.x, _612_fa_tr_a.y, _612_fa_tr_b.xyz, _612_fa_tr_a.z };\n    return _9893;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1868 = rect.zw - rect.xy;\n    float2 _1872 = _1868 * atlas;\n    float2 _1876 = ddx * _1872;\n    float2 _1880 = ddy * _1872;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1868), clamp(0.5f * log2(max(max(dot(_1876, _1876), dot(_1880, _1880)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1913 = _612_fa_counts.y < 0.5f;\n    bool _1920;\n    if (!_1913)\n    {\n        _1920 = _612_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1920 = _1913;\n    }\n    if (_1920)\n    {\n        return;\n    }\n    float3 _1926 = ddx(world_pos);\n    float3 _1929 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1933 = fa_cluster_texel(param);\n    int _1937 = int(_1933.w);\n    if (_1937 < 1)\n    {\n        return;\n    }\n    int _1947 = int(_612_fa_counts.y + 0.5f);\n    int param_1 = _1947;\n    float4 _1951 = fa_light_texel(param_1);\n    float2 _1954 = _1951.yz;\n    int _1958 = int(_1951.w);\n    int param_2 = _1947 + 1;\n    float4 _1963 = fa_light_texel(param_2);\n    float _1964 = _1963.x;\n    int _1970 = int(_612_fa_counts.w + 0.5f) - 1;\n    int _1974 = int(_1933.z);\n    float3 _2239;\n    for (int k = 0; k < _1937; k++)\n    {\n        int _1987 = _1974 + k;\n        int param_3 = _1958 + (_1987 >> 2);\n        int _2004 = (_1947 + 2) + (int(fa_light_texel(param_3)[_1987 & 3]) * 7);\n        int param_4 = _2004 + 6;\n        float4 _2009 = fa_light_texel(param_4);\n        if (((int(_2009.w + 0.5f) >> _1970) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2004;\n        float4 _2024 = fa_light_texel(param_5);\n        int param_6 = _2004 + 1;\n        float4 _2029 = fa_light_texel(param_6);\n        int param_7 = _2004 + 2;\n        float4 _2034 = fa_light_texel(param_7);\n        float3 _2037 = _2024.xyz;\n        float _2042 = dot(_2037, world_pos) + _2024.w;\n        float3 _2044 = _2029.xyz;\n        float _2049 = dot(_2044, world_pos) + _2029.w;\n        float3 _2051 = _2034.xyz;\n        float _2056 = dot(_2051, world_pos) + _2034.w;\n        bool _2061 = abs(_2042) > 0.5f;\n        bool _2069;\n        if (!_2061)\n        {\n            _2069 = abs(_2049) > 0.5f;\n        }\n        else\n        {\n            _2069 = _2061;\n        }\n        bool _2077;\n        if (!_2069)\n        {\n            _2077 = abs(_2056) > 0.5f;\n        }\n        else\n        {\n            _2077 = _2069;\n        }\n        if (_2077)\n        {\n            continue;\n        }\n        float _2092 = clamp(dot(geo_normal, normalize(_2051)) * _2009.z, 0.0f, 1.0f);\n        if (_2092 <= 0.0f)\n        {\n            continue;\n        }\n        float _2112 = (clamp((0.5f - abs(_2056)) * 10.0f, 0.0f, 1.0f) * _2092) * _2009.x;\n        float2 _2120 = float2(_2042 + 0.5f, 0.5f - _2049);\n        float2 _2130 = float2(dot(_2037, _1926), dot(_2044, _1926));\n        float2 _2140 = float2(dot(_2037, _1929), dot(_2044, _1929));\n        int param_8 = _2004 + 5;\n        float4 _2145 = fa_light_texel(param_8);\n        int param_9 = _2004 + 3;\n        float4 _2150 = fa_light_texel(param_9);\n        int param_10 = _2004 + 4;\n        float4 _2155 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2145.xyz;\n        bool _2165 = _2150.z > _2150.x;\n        if (_2165)\n        {\n            float4 param_11 = _2150;\n            float2 param_12 = _2120;\n            float2 param_13 = _1954;\n            float2 param_14 = _2130;\n            float2 param_15 = _2140;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1964 > 0.5f) && (_1964 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2191 = fa_dc_to_linear(param_16);\n                float4 _9943 = tx;\n                _9943.x = _2191.x;\n                _9943.y = _2191.y;\n                _9943.z = _2191.z;\n                tx = _9943;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2112 * tex_a) * _2145.w, 0.0f, 1.0f).xxx);\n        if (_2155.z > _2155.x)\n        {\n            float4 param_17 = _2155;\n            float2 param_18 = _2120;\n            float2 param_19 = _1954;\n            float2 param_20 = _2130;\n            float2 param_21 = _2140;\n            float4 _2235 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1964 > 1.5f)\n            {\n                float3 param_22 = _2235.xyz;\n                float3 _2245 = fa_dc_to_srgb(param_22);\n                _2239 = _2245;\n            }\n            else\n            {\n                _2239 = _2235.xyz;\n            }\n            float3 _2254 = (_2239 * 2.0f) - 1.0f.xxx;\n            float2 _2259 = _2254.xy * _2009.y;\n            float3 _2281 = (normalize(_2037) * _2259.x) + (normalize(_2044) * _2259.y);\n            float3 _2284 = normalize(normal);\n            normal = normalize(lerp(_2284, normalize((_2284 * max(_2254.z, 0.0500000007450580596923828125f)) + (_2281 - (_2284 * dot(_2284, _2281)))), clamp(_2112 * (_2165 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_612_fa_gi.w != 0.0f)\n    {\n        float _633 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _636;\n        if (_612_fa_gi.w > 0.0f)\n        {\n            _636 = _633 >= _612_fa_gi.w;\n        }\n        else\n        {\n            _636 = _633 < (-_612_fa_gi.w);\n        }\n        if (_636)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4775 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4783 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4786 = int(_4775);\n    int _4789 = int(_4783);\n    float _4799 = _4783 - float(_4789);\n    int _4854 = (_4786 * 9) + _4789;\n    int _4874 = ((_4786 + 1) * 9) + _4789;\n    return lerp(lerp(_4850[_4854], _4850[_4854 + 1], _4799), lerp(_4850[_4874], _4850[_4874 + 1], _4799), _4775 - float(_4786));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9778 = false;\n    float _9779 = 1.0f;\n    float _9780 = 1.0f;\n    float _9781 = 1.0f;\n    float _9782 = 0.0f;\n    float _9783 = 0.0f;\n    float _9784 = 0.0f;\n    float _9785 = 0.0f;\n    float _9787 = 1.0f;\n    bool _9788 = false;\n    float3 _9789 = 0.0f.xxx;\n    float _9790 = 1.0f;\n    float _9791 = 1.0f;\n    float _9792 = 1.0f;\n    float _9793 = 0.0f;\n    float _9794 = 0.0f;\n    float3 _9795 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9796 = float3(0.0f, 0.0f, 1.0f);\n    float _9797 = 1.0f;\n    float _9798 = 1.0f;\n    float _4925 = clamp(s.specular, 0.0f, 1.0f);\n    float _4929 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4934 = (_4925 != 1.0f) || (_4929 != 1.5f);\n    bool _4943;\n    if (!_4934)\n    {\n        _4943 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4943 = _4934;\n    }\n    if (_4943)\n    {\n        float _4951 = (_4929 - 1.0f) / (_4929 + 1.0f);\n        f0 = lerp(min((_4951 * _4951).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4925, s.albedo, metallic.xxx);\n        _9779 = lerp(_4925, 1.0f, metallic);\n        _9778 = true;\n    }\n    float _4978 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4978 > 0.0f)\n    {\n        float _4986 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9782 = _4978;\n        _9783 = _4986;\n        float _4993 = _4986 * _4986;\n        _9784 = _4993;\n        _9785 = _4993 * _4993;\n        float _5005 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9787 = _5005;\n        _9780 = 1.0f - (_4978 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _5005, 0.0f, 1.0f), 5.0f))));\n        _9778 = true;\n    }\n    float3 _5024 = max(s.sheen_color, 0.0f.xxx);\n    float _5033 = max(_5024.x, max(_5024.y, _5024.z));\n    if (_5033 > 0.0f)\n    {\n        float _5041 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9788 = true;\n        _9789 = _5024;\n        _9790 = _5041;\n        _9791 = _5041 * _5041;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _5041;\n        float _5058 = fa_sheen_albedo(param, param_1);\n        _9793 = _5058;\n        _9792 = 1.0f - min(_5033 * _5058, 1.0f);\n        _9778 = true;\n    }\n    _9781 = _9780 * _9792;\n    float _5077 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_5077 != 0.0f)\n    {\n        float3 _5092 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _5092;\n        if (dot(_5092, _5092) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _5104 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_5104.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _5104.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _5104.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _5108 = t;\n        float3 _5109 = normalize(_5108);\n        t = _5109;\n        float3 _5134 = normalize((_5109 * cos(s.anisotropy_rotation)) + ((cross(n, _5109) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9795 = _5134;\n        _9796 = cross(n, _5134);\n        float _5144 = roughness * roughness;\n        float _5150 = lerp(_5144, 1.0f, _5077 * _5077);\n        bool _5152 = _5077 > 0.0f;\n        _9797 = _5152 ? _5150 : _5144;\n        _9798 = _5152 ? _5144 : _5150;\n        _9794 = _5077;\n        _9778 = true;\n    }\n    FaLayers _9820 = { _9778, _9779, _9780, _9781, _9782, _9783, _9784, _9785, i.world_normal, _9787, _9788, _9789, _9790, _9791, _9792, _9793, _9794, _9795, _9796, _9797, _9798 };\n    return _9820;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _4005_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _4005_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_612_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3946 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3946;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4557 = (1.0f - _612_fa_rpa_tile.w) - _612_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4562 = _612_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4557 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4562)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _612_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4557;\n            }\n        }\n        else\n        {\n            amb = _612_fa_ambient.xyz * _4557;\n        }\n    }\n    bool _4612 = _612_fa_rpa_tile.w > 0.0f;\n    if (_4612)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _612_fa_rpa_tile.xy;\n            float param_4 = _612_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _612_fa_rpa_tile.w);\n        }\n    }\n    bool _4643 = _612_fa_rpb_tile.w > 0.0f;\n    if (_4643)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _612_fa_rpb_tile.xy;\n            float param_7 = _612_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _612_fa_rpb_tile.w);\n        }\n    }\n    if ((_4562 || _4612) || _4643)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3966 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3969 = _3966.x;\n    float _3971 = _3966.z;\n    float2 e = float2(_3969, _3971);\n    if (_3966.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3971)) * ((_3969 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3969)) * ((_3971 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7992 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7997 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _8002 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _8007 = fa_light_texel(param_3);\n    bool _8010 = _8007.z < 0.5f;\n    bool _8018;\n    if (!_8010)\n    {\n        _8018 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _8018 = _8010;\n    }\n    if (_8018)\n    {\n        return 0.0f.xxx;\n    }\n    float _8025 = max(_7992.w, 9.9999997473787516355514526367188e-05f);\n    float3 _8028 = _7997.xyz;\n    float3 _8032 = _7992.xyz;\n    float3 _8036 = (fa_world_pos - _8032) / _8025.xxx;\n    float3 _8045 = min(_8036 + 0.5f.xxx, (_8028 - 0.5f.xxx) - _8036);\n    float _8054 = min(_8045.x, min(_8045.y, _8045.z));\n    if (!(_8054 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _8069 = _8028 - 1.0f.xxx;\n    float3 _8070 = clamp(_8036, 0.0f.xxx, _8069);\n    float3 _8078 = min(floor(_8070), max(_8028 - 2.0f.xxx, 0.0f.xxx));\n    float3 _8082 = _8070 - _8078;\n    float3 _8093 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _8025));\n    int _8098 = int(_8002.y + 0.5f);\n    float _8103 = 0.3257350027561187744140625f * n.y;\n    float _8107 = 0.3257350027561187744140625f * n.z;\n    float _8111 = 0.3257350027561187744140625f * n.x;\n    float _8118 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _8125 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _8134 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _8141 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _8154 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _8161 = 8 + int(_8007.w);\n    float _8188;\n    float _8201;\n    float _8215;\n    for (int k = 0; k < _8161; k++)\n    {\n        float _8174 = float(k & 1);\n        float _8178 = float((k >> 1) & 1);\n        float _8182 = float((k >> 2) & 1);\n        if (_8174 > 0.5f)\n        {\n            _8188 = _8082.x;\n        }\n        else\n        {\n            _8188 = 1.0f - _8082.x;\n        }\n        if (_8178 > 0.5f)\n        {\n            _8201 = _8082.y;\n        }\n        else\n        {\n            _8201 = 1.0f - _8082.y;\n        }\n        if (_8182 > 0.5f)\n        {\n            _8215 = _8082.z;\n        }\n        else\n        {\n            _8215 = 1.0f - _8082.z;\n        }\n        float _8225 = (_8188 * _8201) * _8215;\n        if (!(_8225 > 0.0f))\n        {\n            continue;\n        }\n        float3 _8238 = min(_8078 + float3(_8174, _8178, _8182), _8069);\n        int _8258 = int(((_8002.x + _8238.x) + (_7997.x * (_8238.y + (_7997.y * _8238.z)))) + 0.5f);\n        float2 _8273 = float2(float(_8258 % _8098) * 10.0f, 1024.0f + (float(_8258 / _8098) * 11.0f));\n        float2 param_4 = _8273 + float2(9.5f, 10.5f);\n        float4 _8281 = fa_gi_fetch(param_4);\n        bool _8284 = _8281.y < 0.5f;\n        bool _8293;\n        if (!_8284)\n        {\n            _8293 = _8281.x > _8007.y;\n        }\n        else\n        {\n            _8293 = _8284;\n        }\n        if (_8293)\n        {\n            continue;\n        }\n        float3 _8305 = _8093 - (_8032 + (_8238 * _8025));\n        float _8308 = length(_8305);\n        float3 _8314 = _8305 / max(_8308, 9.9999997473787516355514526367188e-05f).xxx;\n        float _8324 = max(9.9999997473787516355514526367188e-05f, (dot(-_8314, n) + 1.0f) * 0.5f);\n        float w = _8225 * (_8324 * _8324);\n        float3 param_5 = _8314;\n        float2 param_6 = (_8273 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _8343 = fa_gi_fetch(param_6);\n        float _8350 = _8308 / max(_8002.z, 9.9999997473787516355514526367188e-05f);\n        float _8353 = _8343.x;\n        if (_8350 > _8353)\n        {\n            float _8366 = max(_8343.y - (_8353 * _8353), 0.0f);\n            float _8371 = _8350 - _8353;\n            float _8380 = _8366 / max(_8366 + (_8371 * _8371), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8380 * _8380) * _8380);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _8273 + float2(0.5f, 10.5f);\n        float2 param_8 = _8273 + float2(1.5f, 10.5f);\n        float2 param_9 = _8273 + float2(2.5f, 10.5f);\n        float2 param_10 = _8273 + float2(3.5f, 10.5f);\n        float2 param_11 = _8273 + float2(4.5f, 10.5f);\n        float2 param_12 = _8273 + float2(5.5f, 10.5f);\n        float2 param_13 = _8273 + float2(6.5f, 10.5f);\n        float2 param_14 = _8273 + float2(7.5f, 10.5f);\n        float2 param_15 = _8273 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _8103)) + (fa_gi_fetch(param_9).xyz * _8107)) + (fa_gi_fetch(param_10).xyz * _8111)) + (fa_gi_fetch(param_11).xyz * _8118)) + (fa_gi_fetch(param_12).xyz * _8125)) + (fa_gi_fetch(param_13).xyz * _8134)) + (fa_gi_fetch(param_14).xyz * _8141)) + (fa_gi_fetch(param_15).xyz * _8154)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_8054 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8504;\n    if (_612_fa_gi.z > 0.5f)\n    {\n        _8504 = _8007.x;\n    }\n    else\n    {\n        _8504 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_8002.w * _8504);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8528 = normalize(_612_fa_camera_pos.xyz - fa_world_pos);\n    int _8533 = int(_612_fa_gi.x + 0.5f);\n    int _8538 = int(_612_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8538) && (k < 8); k++)\n    {\n        int param = _8533 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8528;\n        float3 _8563 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8568 = param_3 * left;\n        acc += (_8563 * _8568);\n        left -= _8568;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_612_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8597 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8597;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_612_fa_gi_px.x > 0.5f)\n    {\n        float4 _8639 = float4(fa_world_pos, 1.0f);\n        float2 _8658 = float2(dot(_612_fa_ct_vpx, _8639), dot(_612_fa_ct_vpy, _8639)) / max(dot(_612_fa_ct_vpw, _8639), 9.9999997473787516355514526367188e-05f).xx;\n        float _8667;\n        if (_612_fa_ct_a.y > 0.5f)\n        {\n            _8667 = (_8658.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _8667 = 0.5f - (_8658.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_8658.x * 0.5f) + 0.5f, _8667) * _612_fa_ct_a.zw), int2(0, 0), int2(_612_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_612_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _612_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_612_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_612_fa_cl_info.x) + int(_612_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_612_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6454;\n    if (fa_lm.z > 0.5f)\n    {\n        _6454 = 0.0f;\n    }\n    else\n    {\n        _6454 = 1.0f - clamp(_612_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6465 = _6454 < 1.0f;\n    bool _6471;\n    if (_6465)\n    {\n        int param = li;\n        _6471 = fa_light_baked(param);\n    }\n    else\n    {\n        _6471 = _6465;\n    }\n    return _6471 ? _6454 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _767_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _767_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _886 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _899 = (c - (ru * hx)) - p;\n        float3 _905 = ru * (2.0f * hx);\n        float _911 = max(dot(_905, _905), 9.9999999392252902907785028219223e-09f);\n        float _915 = dot(_899, _905);\n        float t = clamp((-_915) / _911, 0.0f, 1.0f);\n        if (_886)\n        {\n            float _930 = dot(r, _905);\n            float _936 = _911 - (_930 * _930);\n            if (abs(_936) > (9.9999997473787516355514526367188e-06f * _911))\n            {\n                t = clamp(((dot(r, _899) * _930) - _915) / _936, 0.0f, 1.0f);\n            }\n        }\n        return (p + _899) + (_905 * t);\n    }\n    float3 q = p;\n    float _968 = dot(r, axis);\n    bool _976;\n    if (_886)\n    {\n        _976 = abs(_968) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _976 = _886;\n    }\n    if (_976)\n    {\n        float _986 = dot(c - p, axis) / _968;\n        if (_986 > 0.0f)\n        {\n            q = p + (r * _986);\n        }\n    }\n    float3 _999 = q - c;\n    float2 xy = float2(dot(_999, ru), dot(_999, uu));\n    if (shape > 0.5f)\n    {\n        float _1014 = length(xy);\n        if (_1014 > hx)\n        {\n            xy *= (hx / _1014);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _653 = abs(d);\n    float _655 = _653.x;\n    float _657 = _653.y;\n    bool _658 = _655 >= _657;\n    bool _666;\n    if (_658)\n    {\n        _666 = _655 >= _653.z;\n    }\n    else\n    {\n        _666 = _658;\n    }\n    int _667;\n    if (_666)\n    {\n        _667 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _681;\n        if (_657 >= _653.z)\n        {\n            _681 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _681 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _667 = _681;\n    }\n    return _667;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _806 = dot(d, right);\n    float _810 = dot(d, up);\n    float _821;\n    if (((_806 * _806) + (_810 * _810)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _821 = atan2(_810, _806) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _821 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_821 - floor(_821)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1052 = fa_light_base(param);\n    bool _1056 = _612_fa_ambient.w > 4.5f;\n    int param_1 = _1052;\n    float4 _1060 = fa_light_texel(param_1);\n    int param_2 = _1052 + 1;\n    float4 _1065 = fa_light_texel(param_2);\n    float _1068 = _1065.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1080 = _1056 && (_1068 > 2.5f);\n    fa_light_is_area = _1080;\n    bool _1082 = _1068 < 0.5f;\n    float3 l;\n    if (_1082)\n    {\n        l = normalize(_1060.xyz);\n        if (_1056)\n        {\n            int param_3 = _1052 + 6;\n            float4 _1096 = fa_light_texel(param_3);\n            if (_1096.z > 0.5f)\n            {\n                int param_4 = _1052 + 4;\n                float4 _1106 = fa_light_texel(param_4);\n                int param_5 = _1052 + 5;\n                float4 _1111 = fa_light_texel(param_5);\n                float2 param_6 = _1096.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1106.xyz) * _1106.w, (-dot(world_pos, _1111.xyz)) * _1111.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1141 = _1060.xyz;\n        float3 _1143 = _1141 - world_pos;\n        float3 to_light = _1143;\n        float _1146 = length(_1143);\n        float reach = _1146;\n        bool front = true;\n        if (_1080)\n        {\n            int param_8 = _1052 + 7;\n            reach = max(_1146 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1052 + 4;\n            float4 _1170 = fa_light_texel(param_9);\n            int param_10 = _1052 + 5;\n            float4 _1175 = fa_light_texel(param_10);\n            int param_11 = _1052 + 6;\n            float4 _1180 = fa_light_texel(param_11);\n            float _1181 = _1180.w;\n            int param_12 = _1052 + 2;\n            float3 _1188 = normalize(fa_light_texel(param_12).xyz);\n            bool _1190 = _1181 > 1.5f;\n            bool _1198;\n            if (!_1190)\n            {\n                _1198 = dot(_1188, to_light) < 0.0f;\n            }\n            else\n            {\n                _1198 = _1190;\n            }\n            front = _1198;\n            float3 r = 0.0f.xxx;\n            float3 _1207 = _612_fa_camera_pos.xyz - world_pos;\n            bool _1211 = dot(n, n) > 0.5f;\n            bool _1219;\n            if (_1211)\n            {\n                _1219 = dot(_1207, _1207) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1219 = _1211;\n            }\n            if (_1219)\n            {\n                r = reflect(-normalize(_1207), normalize(n));\n            }\n            float3 param_13 = _1141;\n            float3 param_14 = _1188;\n            float3 param_15 = _1170.xyz;\n            float3 param_16 = _1175.xyz;\n            float param_17 = _1170.w;\n            float param_18 = _1175.w;\n            float param_19 = _1181;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1255 = length(to_light);\n        dist = _1255;\n        l = to_light / max(_1255, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1269 = reach / max(_1060.w, 0.001000000047497451305389404296875f);\n        float _1275 = clamp(1.0f - (_1269 * _1269), 0.0f, 1.0f);\n        float _1277;\n        if (front)\n        {\n            _1277 = _1275 * _1275;\n        }\n        else\n        {\n            _1277 = 0.0f;\n        }\n        atten = _1277;\n        bool _1288 = _1068 < 2.5f;\n        if ((_1068 > 1.5f) && _1288)\n        {\n            int param_22 = _1052 + 2;\n            float4 _1296 = fa_light_texel(param_22);\n            float _1306 = _1296.w;\n            int param_23 = _1052 + 3;\n            float4 _1311 = fa_light_texel(param_23);\n            float _1312 = _1311.x;\n            float cos_inner = _1312;\n            if (_1312 > 1.5f)\n            {\n                cos_inner = lerp(_1306, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1306, cos_inner, dot(-l, normalize(_1296.xyz)));\n        }\n        if (_1056 && (_1068 < 1.5f))\n        {\n            int param_24 = _1052 + 6;\n            float4 _1336 = fa_light_texel(param_24);\n            if (_1336.z > 0.5f)\n            {\n                float3 _1344 = -to_light;\n                int param_25 = _1052 + 4;\n                int param_26 = _1052 + 5;\n                float3 _1358 = fa_light_texel(param_25).xyz;\n                float3 _1362 = fa_light_texel(param_26).xyz;\n                float3 _1371 = float3(dot(_1344, _1358), dot(_1344, _1362), dot(_1344, cross(_1358, _1362)));\n                float3 param_27 = _1371;\n                int _1375 = fa_cube_face(param_27);\n                int param_28 = _1375;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1402 = float2(dot(_1371, cross(param_29, param_30)), dot(_1371, param_30)) / max(dot(_1371, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1406 = _1375 / 3;\n                float2 param_31 = _1336.xy + (float2(float(_1375 - (_1406 * 3)), float(_1406)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1402.x), 0.5f - (0.5f * _1402.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1052 + 7;\n            float4 _1436 = fa_light_texel(param_33);\n            if (_1436.z > 0.5f)\n            {\n                int param_34 = _1052 + 2;\n                int param_35 = _1052 + 4;\n                int param_36 = _1052 + 5;\n                float2 param_37 = _1436.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1056 && _1288)\n            {\n                int param_42 = _1052 + 6;\n                float4 _1483 = fa_light_texel(param_42);\n                int param_43 = _1052 + 7;\n                float4 _1488 = fa_light_texel(param_43);\n                bool _1491 = _1483.z > 0.5f;\n                bool _1498;\n                if (!_1491)\n                {\n                    _1498 = _1488.z > 0.5f;\n                }\n                else\n                {\n                    _1498 = _1491;\n                }\n                if (_1498)\n                {\n                    int param_44 = _1052 + 2;\n                    float4 _1505 = fa_light_texel(param_44);\n                    float3 _1509 = normalize(_1505.xyz);\n                    int param_45 = _1052 + 4;\n                    float4 _1514 = fa_light_texel(param_45);\n                    int param_46 = _1052 + 5;\n                    float4 _1519 = fa_light_texel(param_46);\n                    if (_1491)\n                    {\n                        float3 _1527 = -to_light;\n                        float _1534 = _1505.w;\n                        float _1550 = 0.5f / max(dot(_1527, _1509) * (sqrt(max(1.0f - (_1534 * _1534), 0.0f)) / max(_1534, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1483.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1527, _1514.xyz) * _1550), 0.5f - (dot(_1527, _1519.xyz) * _1550));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1488.z > 0.5f)\n                    {\n                        float2 param_49 = _1488.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1509;\n                        float3 param_52 = _1514.xyz;\n                        float3 param_53 = _1519.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9766 = _1065.xyz * atten;\n    if (_1056)\n    {\n        _9766 *= fa_light_tint;\n    }\n    int _1619;\n    if (_1082)\n    {\n        _1619 = 0;\n    }\n    else\n    {\n        _1619 = ((_1068 > 1.5f) && (_1068 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9777 = { l, _9766, atten, 1.0f, dist, _1619 };\n    return _9777;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2345;\n    if (i == 0)\n    {\n        _2345 = _2355_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2361;\n        if (i == 1)\n        {\n            _2361 = _2355_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2369;\n            if (i == 2)\n            {\n                _2369 = _2355_fa_shadow_split.z;\n            }\n            else\n            {\n                _2369 = _2355_fa_shadow_split.w;\n            }\n            _2361 = _2369;\n        }\n        _2345 = _2361;\n    }\n    return _2345;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2402 = fa_shadow_depth(param, param_1);\n    float _2406;\n    if (conv.x < 0.5f)\n    {\n        _2406 = _2402;\n    }\n    else\n    {\n        _2406 = (conv.y * conv.z) / (conv.z - (_2402 * (conv.z - conv.y)));\n    }\n    return _2406;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2452 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2458 = float2(cos(_2452), sin(_2452));\n    float2 dir = _2458;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2467;\n        if (k < 0.0f)\n        {\n            _2467 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2467 = k;\n        }\n        float _2486 = clamp((_2467 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2505 = sqrt((float(i) + 0.5f) * 0.0625f) * _2486;\n            float2 param_3 = uv + (dir * (_2355_fa_shadow_bias.zw * _2505));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2519 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2519 < (zr - (_2505 * plane)))\n            {\n                sum += _2519;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2547 = sum / cnt;\n        float _2557;\n        if (k < 0.0f)\n        {\n            _2557 = (-k) / max(_2547, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2557 = k;\n        }\n        radius = clamp(((max(zr - _2547, 0.0f) * unit) * _2557) / texel_m, 1.5f, 16.0f);\n        dir = _2458;\n    }\n    float lit = 0.0f;\n    int _2583 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2583; i_1++)\n    {\n        float _2602 = sqrt((float(i_1) + 0.5f) / float(_2583)) * radius;\n        float2 param_7 = uv + (dir * (_2355_fa_shadow_bias.zw * _2602));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2602 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2583);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2648 = max(_2355_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2653 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2659 = sqrt(1.0f - (_2653 * _2653));\n    float _2667 = min(_2659 / max(_2653, 0.20000000298023223876953125f), 4.0f);\n    float _2672;\n    if (_2355_fa_shadow_bias.y > 0.0f)\n    {\n        _2672 = _2355_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2672 = 1.5f * _2355_fa_shadow_info[ci].x;\n    }\n    float4 _2697 = mul(float4(world + (n * (_2672 * _2659)), 1.0f), _2355_fa_shadow_mat[ci]);\n    float _2704 = _2697.x;\n    bool _2707 = _2704 < _2355_fa_shadow_rect[ci].x;\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2704 > _2355_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2697.y < _2355_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2697.y > _2355_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2741;\n    if (!_2734)\n    {\n        _2741 = _2697.z > 1.0f;\n    }\n    else\n    {\n        _2741 = _2734;\n    }\n    if (_2741)\n    {\n        return -1.0f;\n    }\n    float _2749;\n    if (_2355_fa_shadow_bias.x > 0.0f)\n    {\n        _2749 = _2355_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2749 = 1.5f * _2355_fa_shadow_info[ci].x;\n    }\n    float2 param = _2697.xy;\n    float4 param_1 = _2355_fa_shadow_rect[ci];\n    float param_2 = _2697.z - ((_2749 * (1.0f + (0.5f * _2667))) / _2648);\n    float param_3 = _2355_fa_shadow_info[ci].x;\n    float param_4 = _2648;\n    float param_5 = _2648 * 0.25f;\n    float param_6 = ((_2355_fa_shadow_info[ci].x * min(_2667, 3.0f)) * 0.5f) / _2648;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2355_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2355_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_612_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3127 = int(_2355_fa_shadow_cfg.x + 0.5f);\n    if (_3127 < 1)\n    {\n        return 1.0f;\n    }\n    float _3142 = dot(world - _2355_fa_shadow_eye.xyz, _2355_fa_shadow_fwd.xyz);\n    int param = _3127 - 1;\n    if (_3142 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3154 = _3127 > 1;\n    bool _3161;\n    if (_3154)\n    {\n        _3161 = _3142 > _2355_fa_shadow_split.x;\n    }\n    else\n    {\n        _3161 = _3154;\n    }\n    if (_3161)\n    {\n        ci = 1;\n    }\n    bool _3165 = _3127 > 2;\n    bool _3172;\n    if (_3165)\n    {\n        _3172 = _3142 > _2355_fa_shadow_split.y;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        ci = 2;\n    }\n    bool _3176 = _3127 > 3;\n    bool _3183;\n    if (_3176)\n    {\n        _3183 = _3142 > _2355_fa_shadow_split.z;\n    }\n    else\n    {\n        _3183 = _3176;\n    }\n    if (_3183)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3194 = min(_3127, 4);\n    float _3235;\n    for (int c = ci; c < _3194; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3214 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3214;\n            break;\n        }\n        if (_3214 < 0.0f)\n        {\n            continue;\n        }\n        s = _3214;\n        ci = c;\n        if (_2355_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3235 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3235 = _2355_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3254 = _2355_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3235, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3142 - (fa_shadow_split_at(param_7) - _3254)) / _3254, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3286;\n        if ((ci + 1) < _3127)\n        {\n            _3286 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3286 = 1.0f;\n        }\n        s = lerp(s, _3286, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3391 = _612_fa_ct_b.y > 0.5f;\n    bool _3397;\n    if (_3391)\n    {\n        _3397 = _612_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3397 = _3391;\n    }\n    if (_3397)\n    {\n        float _3411 = dot(_612_fa_ct_fwd.xyz, fa_world_pos) + _612_fa_ct_fwd.w;\n        float4 _3419 = float4(fa_world_pos, 1.0f);\n        float _3425 = dot(_612_fa_ct_vpw, _3419);\n        if (_3425 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3444 = float2(dot(_612_fa_ct_vpx, _3419), dot(_612_fa_ct_vpy, _3419)) / _3425.xx;\n            float _3449 = (_3444.x * 0.5f) + 0.5f;\n            float _3453;\n            if (_612_fa_ct_a.y > 0.5f)\n            {\n                _3453 = (_3444.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3453 = 0.5f - (_3444.y * 0.5f);\n            }\n            bool _3469 = _3449 >= 0.0f;\n            bool _3475;\n            if (_3469)\n            {\n                _3475 = _3449 < 1.0f;\n            }\n            else\n            {\n                _3475 = _3469;\n            }\n            bool _3481;\n            if (_3475)\n            {\n                _3481 = _3453 >= 0.0f;\n            }\n            else\n            {\n                _3481 = _3475;\n            }\n            bool _3487;\n            if (_3481)\n            {\n                _3487 = _3453 < 1.0f;\n            }\n            else\n            {\n                _3487 = _3481;\n            }\n            if (_3487)\n            {\n                float4 _3513 = fa_screen_tex.Load(int3(clamp(int2(float2(_3449, _3453) * _612_fa_ct_a.zw), int2(0, 0), int2(_612_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3516 = _3513.w > 0.5f;\n                bool _3532;\n                if (_3516)\n                {\n                    _3532 = abs(_3411 - _3513.x) <= (((0.00200000009499490261077880859375f * _3411) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3532 = _3516;\n                }\n                if (_3532)\n                {\n                    float _3538;\n                    if (_612_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3538 = min(_3513.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3538 = _3513.y;\n                    }\n                    return _3538;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2807 = _612_fa_pbr.z < 0.5f;\n    bool _2814;\n    if (!_2807)\n    {\n        _2814 = _2355_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2814 = _2807;\n    }\n    if (_2814)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2355_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2827 = fa_light_texel(param);\n    float _2828 = _2827.x;\n    if (_2828 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2837 = int(_2828 + 0.5f);\n    int param_1 = _2837;\n    float4 _2841 = fa_light_texel(param_1);\n    int param_2 = _2837 + 1;\n    float4 _2846 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2849 = _2841.y;\n    if (_2849 > 0.0f)\n    {\n        float _2866 = 1.0f - smoothstep(0.75f * _2849, _2849, length(world - _2355_fa_shadow_eye.xyz));\n        fade = _2866;\n        if (_2866 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2841.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2890 = (_2837 + 2) + (face * 6);\n    int param_4 = _2890;\n    int param_5 = _2890 + 1;\n    int param_6 = _2890 + 3;\n    float4 _2904 = fa_light_texel(param_6);\n    int param_7 = _2890 + 4;\n    float4 _2909 = fa_light_texel(param_7);\n    int param_8 = _2890 + 5;\n    float4 _2914 = fa_light_texel(param_8);\n    float _2926 = _2914.x * max(dot(_2904, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2931 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2954 = clamp(dot(n, _2904.xyz), -1.0f, 1.0f);\n    float _2973 = min(sqrt(1.0f - (_2954 * _2954)) / max(abs(dot(n, world - lpos)) / max(dot(_2904, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2976 = _2846.y;\n    float _2978;\n    if (_2976 > 0.0f)\n    {\n        _2978 = _2976;\n    }\n    else\n    {\n        _2978 = 1.5f * _2926;\n    }\n    float4 _2998 = float4(world + (n * (_2978 * sqrt(1.0f - (_2931 * _2931)))), 1.0f);\n    float _3002 = dot(_2904, _2998);\n    float _3005 = _2914.y;\n    if (_3002 < _3005)\n    {\n        return 1.0f;\n    }\n    float2 _3020 = float2(dot(fa_light_texel(param_4), _2998), dot(fa_light_texel(param_5), _2998)) / _3002.xx;\n    float _3022 = _3020.x;\n    bool _3025 = _3022 < _2909.x;\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3022 > _2909.z;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3020.y < _2909.y;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    bool _3052;\n    if (!_3043)\n    {\n        _3052 = _3020.y > _2909.w;\n    }\n    else\n    {\n        _3052 = _3043;\n    }\n    if (_3052)\n    {\n        return 1.0f;\n    }\n    float _3058 = _2846.x;\n    float _3060;\n    if (_3058 > 0.0f)\n    {\n        _3060 = _3058;\n    }\n    else\n    {\n        _3060 = 1.5f * _2926;\n    }\n    float2 param_9 = _3020;\n    float4 param_10 = _2909;\n    float param_11 = _3002 - (_3060 * (1.0f + (0.5f * _2973)));\n    float param_12 = _2926;\n    float param_13 = 1.0f;\n    float param_14 = _2914.z * 0.25f;\n    float param_15 = (_2926 * min(_2973, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _3005, _2914.z);\n    int param_17 = int(_2841.z + 0.5f);\n    float param_18 = _2841.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3567 = _612_fa_ct_b.w > 0.5f;\n    bool _3573;\n    if (_3567)\n    {\n        _3573 = _612_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3573 = _3567;\n    }\n    bool _3579;\n    if (_3573)\n    {\n        _3579 = _2355_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3579 = _3573;\n    }\n    if (_3579)\n    {\n        int param = (int(_2355_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3591 = fa_light_texel(param);\n        float _3592 = _3591.z;\n        if (_3592 > 0.5f)\n        {\n            float _3605 = dot(_612_fa_ct_fwd.xyz, world) + _612_fa_ct_fwd.w;\n            float _3611 = ((0.00200000009499490261077880859375f * _3605) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3617 = float4(world, 1.0f);\n            float _3622 = dot(_612_fa_ct_vpw, _3617);\n            if (_3622 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3639 = float2(dot(_612_fa_ct_vpx, _3617), dot(_612_fa_ct_vpy, _3617)) / _3622.xx;\n                float _3644 = (_3639.x * 0.5f) + 0.5f;\n                float _3648;\n                if (_612_fa_ct_a.y > 0.5f)\n                {\n                    _3648 = (_3639.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3648 = 0.5f - (_3639.y * 0.5f);\n                }\n                bool _3664 = _3644 >= 0.0f;\n                bool _3670;\n                if (_3664)\n                {\n                    _3670 = _3644 < 1.0f;\n                }\n                else\n                {\n                    _3670 = _3664;\n                }\n                bool _3676;\n                if (_3670)\n                {\n                    _3676 = _3648 >= 0.0f;\n                }\n                else\n                {\n                    _3676 = _3670;\n                }\n                bool _3682;\n                if (_3676)\n                {\n                    _3682 = _3648 < 1.0f;\n                }\n                else\n                {\n                    _3682 = _3676;\n                }\n                if (_3682)\n                {\n                    int2 _3699 = int2(_612_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3700 = clamp(int2(float2(_3644, _3648) * _612_fa_ct_a.zw), int2(0, 0), _3699);\n                    float _3704;\n                    if (_3592 < 1.5f)\n                    {\n                        _3704 = 1.0f;\n                    }\n                    else\n                    {\n                        _3704 = (_3592 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    int _3726;\n                    int _3732;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3726 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3732 = k - 1;\n                            }\n                            else\n                            {\n                                _3732 = k;\n                            }\n                            _3726 = _3732;\n                        }\n                        float4 _3761 = fa_screen_tex.Load(int3(clamp(_3700 + int2((_3726 % 3) - 1, (_3726 / 3) - 1), int2(0, 0), _3699), 0));\n                        bool _3764 = _3761.w > 0.5f;\n                        bool _3774;\n                        if (_3764)\n                        {\n                            _3774 = abs(_3605 - _3761.x) <= _3611;\n                        }\n                        else\n                        {\n                            _3774 = _3764;\n                        }\n                        if (_3774)\n                        {\n                            best = min(best, mod(floor(_3761.z / _3704), 256.0f) * 0.0039215688593685626983642578125f);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3801;\n                        if (_612_fa_ct_b.z > 0.5f)\n                        {\n                            int param_1 = li;\n                            float3 param_2 = lpos;\n                            float3 param_3 = world;\n                            float3 param_4 = n;\n                            float3 param_5 = l;\n                            _3801 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3801 = best;\n                        }\n                        return _3801;\n                    }\n                }\n            }\n            float _3824;\n            if (_612_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3824 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3824 = 1.0f;\n            }\n            return _3824;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5668 = _612_fa_ct_a.x < 0.5f;\n    bool _5675;\n    if (!_5668)\n    {\n        _5675 = _2355_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5675 = _5668;\n    }\n    if (_5675)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2355_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5688 = fa_light_texel(param);\n    float _5689 = _5688.y;\n    float len = _5689;\n    if (_5689 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5701 = length(world - _612_fa_camera_pos.xyz);\n    float _5710 = 1.0f - smoothstep(0.5f * _612_fa_ct_b.x, _612_fa_ct_b.x, _5701);\n    if (_5710 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5716 = len;\n    float _5719 = min(_5716, 0.89999997615814208984375f * dist);\n    len = _5719;\n    float _5724 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5701);\n    float _5729 = _5724 + (0.5f * _5719);\n    float3 _5735 = world + (gn * _5724);\n    float _5737 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5798;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5752 = (float(k) + _5737) * 0.083333335816860198974609375f;\n        float3 _5760 = _5735 + (l * (_5752 * len));\n        float4 _5766 = float4(_5760, 1.0f);\n        float _5771 = dot(_612_fa_ct_vpw, _5766);\n        if (_5771 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5789 = float2(dot(_612_fa_ct_vpx, _5766), dot(_612_fa_ct_vpy, _5766)) / _5771.xx;\n        float _5793 = _5789.x * 0.5f;\n        float _5794 = _5793 + 0.5f;\n        if (_612_fa_ct_a.y > 0.5f)\n        {\n            _5798 = (_5789.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5798 = 0.5f - (_5789.y * 0.5f);\n        }\n        bool _5814 = _5794 < 0.0f;\n        bool _5821;\n        if (!_5814)\n        {\n            _5821 = _5794 >= 1.0f;\n        }\n        else\n        {\n            _5821 = _5814;\n        }\n        bool _5828;\n        if (!_5821)\n        {\n            _5828 = _5798 < 0.0f;\n        }\n        else\n        {\n            _5828 = _5821;\n        }\n        bool _5835;\n        if (!_5828)\n        {\n            _5835 = _5798 >= 1.0f;\n        }\n        else\n        {\n            _5835 = _5828;\n        }\n        if (_5835)\n        {\n            break;\n        }\n        float4 _5859 = fa_screen_tex.Load(int3(clamp(int2(float2(_5794, _5798) * _612_fa_ct_a.zw), int2(0, 0), int2(_612_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5859.w < 0.5f)\n        {\n            continue;\n        }\n        float _5877 = (dot(_612_fa_ct_fwd.xyz, _5760) + _612_fa_ct_fwd.w) - _5859.x;\n        if ((_5877 > _5724) && (_5877 < _5729))\n        {\n            occ = max(occ, (1.0f - (_5752 * _5752)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5794, 0.5f - _5793), min(_5798, 1.0f - _5798))));\n        }\n    }\n    return 1.0f - (occ * _5710);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6539 = fa_baked_keep(param);\n    if (_6539 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9833 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9833;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6565 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9835 = _6565.color;\n    float _9836 = _6565.attenuation;\n    float _9837 = _6565.shadow;\n    bool _6568 = _6565.type == 0;\n    if (_6568 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6565.direction;\n        float _6579 = fa_shadow_factor(param_5, param_6);\n        _9837 = _6579;\n        _9835 *= _6579;\n    }\n    else\n    {\n        bool _6590 = _6565.type != 0;\n        bool _6596;\n        if (_6590)\n        {\n            _6596 = _9836 > 0.0f;\n        }\n        else\n        {\n            _6596 = _6590;\n        }\n        if (_6596)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6565.direction;\n            float _6615 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9837 = _6615;\n            _9835 *= _6615;\n        }\n    }\n    bool _6625 = _612_fa_ct_a.x > 0.5f;\n    bool _6631;\n    if (_6625)\n    {\n        _6631 = _9836 > 0.0f;\n    }\n    else\n    {\n        _6631 = _6625;\n    }\n    if (_6631)\n    {\n        float _6638;\n        if (_6568)\n        {\n            _6638 = 1000000000.0f;\n        }\n        else\n        {\n            _6638 = _6565._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6565.direction;\n        float param_18 = _6638;\n        float _6656 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9837 *= _6656;\n        _9835 *= _6656;\n    }\n    float _6669 = _9836;\n    float _6670 = _6669 * _6539;\n    _9836 = _6670;\n    float3 _6674 = _9835;\n    float3 _6675 = _6674 * _6539;\n    _9835 = _6675;\n    LightSample _9852 = { _6565.direction, _6675, _6670, _9837, _6565._distance, _6565.type };\n    return _9852;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6709 = v - (n * dot(v, n));\n    float3 t = _6709;\n    float _6713 = dot(_6709, _6709);\n    float l2 = _6713;\n    if (_6713 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6723;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6723 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6723 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6723;\n        l2 = dot(_6723, _6723);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _7110;\n    if ((j == 0) || (j == 7))\n    {\n        _7110 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7120;\n        if ((j == 3) || (j == 4))\n        {\n            _7120 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7120 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7110 = _7120;\n    }\n    float _7141;\n    if ((j == 1) || (j == 2))\n    {\n        _7141 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7150;\n        if ((j == 5) || (j == 6))\n        {\n            _7150 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7150 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7141 = _7150;\n    }\n    return (pc + (ex * _7110)) + (ey * _7141);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6758 = dot(a, a);\n    float _6762 = dot(b, b);\n    if ((_6758 < 1.0000000195414813782625560981111e-24f) || (_6762 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6776 = a * rsqrt(_6758);\n    float3 _6781 = b * rsqrt(_6762);\n    float _6785 = dot(_6776, _6781);\n    float _6788 = abs(_6785);\n    float g = (((((((((((0.0416471660137176513671875f * _6788) - 0.1924748718738555908203125f) * _6788) + 0.4179156124591827392578125f) * _6788) - 0.616057217121124267578125f) * _6788) + 0.777722418308258056640625f) * _6788) - 0.999542415142059326171875f) * _6788) + 1.570791721343994140625f;\n    if (_6785 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6785 * _6785), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6776, _6781) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6845 = a.z > 0.0f;\n    bool _6849 = b.z > 0.0f;\n    if (_6845 && _6849)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6845 != _6849)\n        {\n            float3 _6884 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6884.z = 0.0f;\n            if (_6845)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6884;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6884;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6884;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6884;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6933 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6959 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6985 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _7011 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6933;\n    float3 param_1 = _6959;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6959;\n    float3 param_7 = _6985;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6985;\n    float3 param_13 = _7011;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _7011;\n    float3 param_19 = _6933;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _7179 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _7197;\n    for (int k = 0; k < (2 * _7179); k++)\n    {\n        bool _7194 = k >= _7179;\n        if (_7194)\n        {\n            _7197 = k - _7179;\n        }\n        else\n        {\n            _7197 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_7179 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7243 = 2 * _7197;\n            int param_4 = _7243 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7243 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7243 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _7280 = _7194.xxxx;\n        float4 param_16 = float4(_7280.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _7280.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _7280.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _7280.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _7291 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7194)\n        {\n            float2 _10088 = sum;\n            _10088.y = _10088.y + _7291;\n            sum = _10088;\n        }\n        else\n        {\n            float2 _10091 = sum;\n            _10091.x = _10091.x + _7291;\n            sum = _10091;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7315 = fa_light_base(param);\n    int param_1 = _7315;\n    int param_2 = _7315 + 1;\n    int param_3 = _7315 + 2;\n    int param_4 = _7315 + 4;\n    float4 _7337 = fa_light_texel(param_4);\n    int param_5 = _7315 + 5;\n    float4 _7342 = fa_light_texel(param_5);\n    int param_6 = _7315 + 6;\n    float4 _7347 = fa_light_texel(param_6);\n    float _7348 = _7347.w;\n    float3 _7353 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7355 = _7348 < 1.5f;\n    bool _7362;\n    if (_7355)\n    {\n        _7362 = dot(normalize(fa_light_texel(param_3).xyz), _7353) >= 0.0f;\n    }\n    else\n    {\n        _7362 = _7355;\n    }\n    if (_7362)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7371 = (_7348 > 0.5f) && _7355;\n    float _7375 = _7371 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7378 = _7337.xyz;\n    float _7380 = _7337.w;\n    float3 _7386 = _7342.xyz;\n    float _7388 = _7342.w;\n    float3 up = _7386 * (_7388 * _7375);\n    float _7394;\n    if (_7371)\n    {\n        _7394 = (3.1415927410125732421875f * _7380) * _7380;\n    }\n    else\n    {\n        _7394 = (4.0f * _7380) * _7388;\n    }\n    if (_7348 > 1.5f)\n    {\n        float3 _7420 = cross(_7378, -_7353);\n        float3 perp = _7420;\n        float _7424 = dot(_7420, _7420);\n        float3 _7427;\n        if (_7424 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7427 = perp * rsqrt(_7424);\n        }\n        else\n        {\n            _7427 = _7386;\n        }\n        perp = _7427;\n        up = _7427 * _7388;\n    }\n    float _7448 = max(_7394, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7458 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7458;\n    float3 param_10 = n;\n    float3 param_11 = _7353;\n    float3 param_12 = _7458;\n    float3 param_13 = n;\n    float3 param_14 = _7378 * (_7380 * _7375);\n    float3 param_15 = _7458;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7489 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7489;\n    float2 param_21 = _7489 + float2(64.0f, 0.0f);\n    float4 _7499 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7348;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7511 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7511.x) + (((f0 * _7499.x) + ((f90.xxx - f0) * _7499.y)) * _7511.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_7353, _7353)) + _7448) / _7448) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5405 = 1.0f / alpha;\n    return ((2.0f + _5405) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5405)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5440 = max(dot(L.nc, l), 0.0f);\n    float _5446 = max(dot(L.nc, h), 0.0f);\n    float _5455 = ((_5446 * _5446) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5455) * _5455)) * (0.5f / max(lerp((2.0f * _5440) * L.coat_ndv, _5440 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5440)) * _5440;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7548;\n    if (L.sheen_on)\n    {\n        _7548 = L.sheen_scale;\n    }\n    else\n    {\n        _7548 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7548);\n    float3 _7561 = normalize(l + v);\n    int param = li;\n    float3 _7572 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7581 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7561), 0.0f);\n        float param_3 = _7581;\n        float param_4 = ndv;\n        result += ((L.sheen * _7572) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7581)) * _7581) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7561;\n        float param_8 = max(dot(v, _7561), 0.0f);\n        result += (_7572 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5308 = tdh / at;\n    float _5312 = bdh / ab;\n    float _5324 = ((_5308 * _5308) + (_5312 * _5312)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _5324) * _5324);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5504 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5583 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5583) * _5583);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5504);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5504));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4707 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4710 = _4707.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4710 * _4710, exp2((-9.27999973297119140625f) * ndv)) * _4710) + _4707.y)) + _4707.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _4018;\n    if (lv == 0)\n    {\n        _4018 = 0.0f;\n    }\n    else\n    {\n        _4018 = res + 2.0f;\n    }\n    float _4028;\n    if (lv == 0)\n    {\n        _4028 = 0.0f;\n    }\n    else\n    {\n        _4028 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_4018, _4028)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _4074;\n    if (res > 64.5f)\n    {\n        _4074 = 5.0f;\n    }\n    else\n    {\n        _4074 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _4089 = clamp(rough, 0.0f, 1.0f) * (_4074 - 1.0f);\n    int _4096 = int(min(floor(_4089), _4074 - 2.0f));\n    float _4101 = _4089 - float(_4096);\n    float3 param = d;\n    float2 _4105 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4096;\n    float2 param_4 = _4105;\n    float3 _4115 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4101 < 0.00200000009499490261077880859375f)\n    {\n        return _4115;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4096 + 1;\n    float2 param_8 = _4105;\n    return lerp(_4115, fa_probe_level(param_5, param_6, param_7, param_8), _4101.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _4186 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4193 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4200 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4206 = dot(bx.xyz, d);\n    float _4210 = dot(by.xyz, d);\n    float _4214 = dot(bz.xyz, d);\n    float _4220;\n    if (_4206 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4220 = (1.0f - _4186) / _4206;\n    }\n    else\n    {\n        float _4234;\n        if (_4206 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4234 = ((-1.0f) - _4186) / _4206;\n        }\n        else\n        {\n            _4234 = 1000000015047466219876688855040.0f;\n        }\n        _4220 = _4234;\n    }\n    float tx = _4220;\n    float _4251;\n    if (_4210 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4251 = (1.0f - _4193) / _4210;\n    }\n    else\n    {\n        float _4264;\n        if (_4210 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4264 = ((-1.0f) - _4193) / _4210;\n        }\n        else\n        {\n            _4264 = 1000000015047466219876688855040.0f;\n        }\n        _4251 = _4264;\n    }\n    float ty = _4251;\n    float _4280;\n    if (_4214 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4280 = (1.0f - _4200) / _4214;\n    }\n    else\n    {\n        float _4293;\n        if (_4214 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4293 = ((-1.0f) - _4200) / _4214;\n        }\n        else\n        {\n            _4293 = 1000000015047466219876688855040.0f;\n        }\n        _4280 = _4293;\n    }\n    float _4305 = tx;\n    float _4308 = (_4305 > 0.0f) ? _4305 : 1000000015047466219876688855040.0f;\n    tx = _4308;\n    float _4309 = ty;\n    float _4312 = (_4309 > 0.0f) ? _4309 : 1000000015047466219876688855040.0f;\n    ty = _4312;\n    float _4322 = min(_4308, min(_4312, (_4280 > 0.0f) ? _4280 : 1000000015047466219876688855040.0f));\n    if (_4322 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4338 = (fa_world_pos + (d * _4322)) - posw.xyz;\n    float3 _4343;\n    if (dot(_4338, _4338) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4343 = normalize(_4338);\n    }\n    else\n    {\n        _4343 = d;\n    }\n    return _4343;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4389 = (1.0f - _612_fa_rpa_tile.w) - _612_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4389 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_612_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _612_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4417 = rough * rough;\n            float _4448 = 0.60000002384185791015625f * _4417;\n            base = lerp(lerp(_612_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_612_fa_env_horizon.xyz, _612_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4417)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4448, 0.0500000007450580596923828125f + _4448, d.y).xxx), ((_612_fa_env_sky.xyz + _612_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4417 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4389;\n    }\n    if (_612_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _612_fa_rpa_tile;\n        float4 param_5 = _612_fa_rpa_pos;\n        float4 param_6 = _612_fa_rpa_bx;\n        float4 param_7 = _612_fa_rpa_by;\n        float4 param_8 = _612_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4507 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4507 * _612_fa_rpa_tile.w);\n    }\n    if (_612_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _612_fa_rpb_tile;\n        float4 param_12 = _612_fa_rpb_pos;\n        float4 param_13 = _612_fa_rpb_bx;\n        float4 param_14 = _612_fa_rpb_by;\n        float4 param_15 = _612_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4539 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4539 * _612_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _5185;\n        if (L.aniso >= 0.0f)\n        {\n            _5185 = L.b;\n        }\n        else\n        {\n            _5185 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_5185, v), _5185), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5221 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _5221.x) + (L.f90.xxx * _5221.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _5279 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _5279.x) + _5279.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4749 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4749.x) + _4749.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_612_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_612_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5981 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5985 = fa_xm_origin(param_1);\n    float2 _5991 = (uv * _5981) - 0.5f.xx;\n    float2 _5994 = frac(_5991);\n    float2 _5997 = floor(_5991);\n    float2 param_2 = _5981;\n    float2 param_3 = _5985;\n    float2 param_4 = _5997;\n    float2 param_5 = _5981;\n    float2 param_6 = _5985;\n    float2 param_7 = _5997 + float2(1.0f, 0.0f);\n    float2 param_8 = _5981;\n    float2 param_9 = _5985;\n    float2 param_10 = _5997 + float2(0.0f, 1.0f);\n    float2 param_11 = _5981;\n    float2 param_12 = _5985;\n    float2 param_13 = _5997 + 1.0f.xx;\n    float3 _6039 = _5994.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6039), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6039), _5994.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _6058 = max(_612_fa_tr_b.w - 1.0f, 0.0f);\n    float _6062 = clamp(lod, 0.0f, _6058);\n    int _6066 = int(floor(_6062));\n    int param = _6066;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _6076 = float(_6066);\n    float _6077 = _6062 - _6076;\n    bool _6079 = _6077 > 0.001000000047497451305389404296875f;\n    bool _6086;\n    if (_6079)\n    {\n        _6086 = _6076 < _6058;\n    }\n    else\n    {\n        _6086 = _6079;\n    }\n    if (_6086)\n    {\n        int param_2 = _6066 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _6077.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _6112 = fa_env_brdf(param, param_1);\n    float3 _6136 = ((1.0f.xxx - clamp((f0 * _6112.x) + (f90.xxx * _6112.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _6136;\n    float _6142 = max(s.thickness, 0.0f);\n    bool _6147 = _6142 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _6147)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _6142);\n    }\n    bool _6172 = _612_fa_tr_a.w > 1.5f;\n    bool _6178;\n    if (_6172)\n    {\n        _6178 = _612_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _6178 = _6172;\n    }\n    bool _6185;\n    if (!_6178)\n    {\n        _6185 = _612_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _6185 = _6178;\n    }\n    if (_6185)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _6200 = float4(fa_world_pos, 1.0f);\n    float _6205 = dot(_612_fa_ct_vpw, _6200);\n    float2 uv0 = 0.5f.xx;\n    if (_6205 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _6223 = float2(dot(_612_fa_ct_vpx, _6200), dot(_612_fa_ct_vpy, _6200)) / _6205.xx;\n        float _6231;\n        if (_612_fa_ct_a.y > 0.5f)\n        {\n            _6231 = (_6223.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _6231 = 0.5f - (_6223.y * 0.5f);\n        }\n        uv0 = float2((_6223.x * 0.5f) + 0.5f, _6231);\n    }\n    if (_612_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _6252 = fa_xm_size(param_2);\n        float2 _6260 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _6252);\n        if (fa_screen_tex.Load(int3(int2(_6260), 0)).w > 0.5f)\n        {\n            int _6280 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6303 = abs(dx) > _6280;\n                    bool _6311;\n                    if (!_6303)\n                    {\n                        _6311 = abs(dy) > _6280;\n                    }\n                    else\n                    {\n                        _6311 = _6303;\n                    }\n                    if (_6311)\n                    {\n                        continue;\n                    }\n                    float4 _6332 = fa_screen_tex.Load(int3(int2(clamp(_6260 + float2(float(dx), float(dy)), 0.0f.xx, _6252 - 1.0f.xx)), 0));\n                    if (_6332.w > 0.5f)\n                    {\n                        acc += _6332.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _6136 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_6147)\n    {\n        float4 _6380 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _6142), 1.0f);\n        float _6385 = dot(_612_fa_ct_vpw, _6380);\n        uv = 0.5f.xx;\n        if (_6385 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6402 = float2(dot(_612_fa_ct_vpx, _6380), dot(_612_fa_ct_vpy, _6380)) / _6385.xx;\n            float _6410;\n            if (_612_fa_ct_a.y > 0.5f)\n            {\n                _6410 = (_6402.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6410 = 0.5f - (_6402.y * 0.5f);\n            }\n            uv = float2((_6402.x * 0.5f) + 0.5f, _6410);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_612_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2355_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3314 = int(_2355_fa_shadow_cfg.x + 0.5f);\n    float _3324 = dot(world - _2355_fa_shadow_eye.xyz, _2355_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3329 = _3314 > 0;\n    bool _3338;\n    if (_3329)\n    {\n        int param = _3314 - 1;\n        _3338 = _3324 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3338 = _3329;\n    }\n    if (_3338)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3344 = _3314 > 1;\n        bool _3351;\n        if (_3344)\n        {\n            _3351 = _3324 > _2355_fa_shadow_split.x;\n        }\n        else\n        {\n            _3351 = _3344;\n        }\n        if (_3351)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3357 = _3314 > 2;\n        bool _3364;\n        if (_3357)\n        {\n            _3364 = _3324 > _2355_fa_shadow_split.y;\n        }\n        else\n        {\n            _3364 = _3357;\n        }\n        if (_3364)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3370 = _3314 > 3;\n        bool _3377;\n        if (_3370)\n        {\n            _3377 = _3324 > _2355_fa_shadow_split.z;\n        }\n        else\n        {\n            _3377 = _3370;\n        }\n        if (_3377)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _9494 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9494 = -_9494;\n    }\n    float3 _8780 = normalize(_612_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9507 = { fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing };\n    SurfaceInput param_1 = _9507;\n    Surface _8788 = fa_standard_surface(param_1);\n    float3 _9525 = _8788.albedo;\n    float _9526 = _8788.alpha;\n    float3 _9527 = _8788.normal;\n    float _9528 = _8788.metallic;\n    float _9529 = _8788.roughness;\n    float _9530 = _8788.occlusion;\n    float3 _9531 = _8788.emission;\n    float _9532 = _8788.clearcoat;\n    float _9533 = _8788.clearcoat_roughness;\n    float3 _9534 = _8788.sheen_color;\n    float _9535 = _8788.sheen_roughness;\n    float _9536 = _8788.anisotropy;\n    float _9537 = _8788.anisotropy_rotation;\n    float _9538 = _8788.specular;\n    float _9539 = _8788.ior;\n    float3 _9540 = _8788.specular_color;\n    float _9541 = _8788.transmission;\n    float _9542 = _8788.thickness;\n    float3 _9543 = _8788.attenuation_color;\n    float _9544 = _8788.attenuation_distance;\n    SurfaceInput _9515 = { fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing };\n    SurfaceInput param_2 = _9515;\n    Surface param_3 = _8788;\n    surface(param_2, param_3);\n    _9525 = param_3.albedo;\n    _9526 = param_3.alpha;\n    _9527 = param_3.normal;\n    _9528 = param_3.metallic;\n    _9529 = param_3.roughness;\n    _9530 = param_3.occlusion;\n    _9531 = param_3.emission;\n    _9532 = param_3.clearcoat;\n    _9533 = param_3.clearcoat_roughness;\n    _9534 = param_3.sheen_color;\n    _9535 = param_3.sheen_roughness;\n    _9536 = param_3.anisotropy;\n    _9537 = param_3.anisotropy_rotation;\n    _9538 = param_3.specular;\n    _9539 = param_3.ior;\n    _9540 = param_3.specular_color;\n    _9541 = param_3.transmission;\n    _9542 = param_3.thickness;\n    _9543 = param_3.attenuation_color;\n    _9544 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9494;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9525 = param_6;\n    _9527 = param_7;\n    if (_9526 < _8816_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_612_fa_emissive.w > 0.5f)\n    {\n        result = _9525;\n    }\n    else\n    {\n        float3 _8840 = normalize(_9527);\n        float _8847 = clamp(_9528, 0.0f, 1.0f);\n        float _8851 = clamp(_9529, 0.0500000007450580596923828125f, 1.0f);\n        float _8855 = _8851 * _8851;\n        float _8859 = _8855 * _8855;\n        float _8864 = max(dot(_8840, _8780), 9.9999997473787516355514526367188e-05f);\n        float _8870 = 1.0f - _8847;\n        float _8871 = clamp(_9541, 0.0f, 1.0f) * _8870;\n        float3 _8880 = (_9525 * _8870) * (1.0f - _8871);\n        float3 _8887 = lerp(0.039999999105930328369140625f.xxx, _9525, _8847.xxx);\n        float3 f0 = _8887;\n        SurfaceInput _9523 = { fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing };\n        SurfaceInput param_8 = _9523;\n        Surface _9626 = { _9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544 };\n        Surface param_9 = _9626;\n        float3 param_10 = _8840;\n        float3 param_11 = _8780;\n        float param_12 = _8847;\n        float param_13 = _8851;\n        float3 param_14 = _8887;\n        FaLayers _8903 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8840;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8880) * _9530;\n        if (_8903.on)\n        {\n            lit *= _8903.base_scale;\n        }\n        int _8925 = fa_cl_ndir + fa_cl_local;\n        float _8990;\n        for (int ln = 0; ln < _8925; ln++)\n        {\n            int param_16 = ln;\n            int _8938 = fa_cl_light(param_16);\n            int param_17 = _8938;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8938;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9494;\n            LightSample _8954 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8962 = max(dot(_8840, _8954.direction), 0.0f);\n            float _8968 = _8954.attenuation * _8954.shadow;\n            float3 _8973 = normalize(_8954.direction + _8780);\n            float _8978 = max(dot(_8840, _8973), 0.0f);\n            float _8983 = max(dot(_8780, _8973), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8903.on)\n                {\n                    _8990 = _8903.f90;\n                }\n                else\n                {\n                    _8990 = 1.0f;\n                }\n                int param_21 = _8938;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8840;\n                float3 param_24 = _8780;\n                float3 param_25 = _8880;\n                float3 param_26 = f0;\n                float param_27 = _8990;\n                float param_28 = _8851;\n                float param_29 = _8864;\n                float param_30 = _8968;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8903.on)\n                {\n                    FaLayers param_31 = _8903;\n                    float3 param_32 = area;\n                    int param_33 = _8938;\n                    float3 param_34 = _8840;\n                    float3 param_35 = _8780;\n                    float3 param_36 = _8954.direction;\n                    float param_37 = _8864;\n                    float param_38 = _8968;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8903.on)\n                {\n                    FaLayers param_39 = _8903;\n                    float3 param_40 = _8880;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8840;\n                    float3 param_43 = _8780;\n                    float3 param_44 = _8954.direction;\n                    float3 param_45 = _8973;\n                    float param_46 = _8962;\n                    float param_47 = _8864;\n                    float param_48 = _8978;\n                    float param_49 = _8983;\n                    float param_50 = _8855;\n                    float param_51 = _8859;\n                    int param_52 = _8938;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8968));\n                }\n                else\n                {\n                    float _9092 = ((_8978 * _8978) * (_8859 - 1.0f)) + 1.0f;\n                    int param_53 = _8938;\n                    lit += (((_8880 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8983, 5.0f))) * (((_8859 / ((3.1415927410125732421875f * _9092) * _9092)) * (0.5f / max(lerp((2.0f * _8962) * _8864, _8962 + _8864, _8855), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8962))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8962 * _8968));\n                }\n            }\n        }\n        if (_8903.on)\n        {\n            FaLayers param_54 = _8903;\n            float3 param_55 = _8840;\n            float3 param_56 = _8780;\n            float3 param_57 = f0;\n            float param_58 = _8851;\n            float param_59 = _9530;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8840;\n            float3 param_61 = _8780;\n            float3 param_62 = f0;\n            float param_63 = _8851;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9530);\n        }\n        if (_8871 > 0.0f)\n        {\n            float _9190;\n            if (_8903.on)\n            {\n                _9190 = _8903.f90;\n            }\n            else\n            {\n                _9190 = 1.0f;\n            }\n            float _9198;\n            if (_8903.on)\n            {\n                _9198 = _8903.base_scale;\n            }\n            else\n            {\n                _9198 = 1.0f;\n            }\n            Surface _9647 = { _9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544 };\n            Surface param_64 = _9647;\n            float3 param_65 = _8840;\n            float3 param_66 = _8780;\n            float param_67 = _8851;\n            float3 param_68 = f0;\n            float param_69 = _9190;\n            float param_70 = _9198;\n            float param_71 = _8871;\n            float param_72 = fa_tr_blend;\n            float3 _9222 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9222;\n        }\n        result = lit;\n    }\n    float3 _9229 = result;\n    float3 _9230 = _9229 + _9531;\n    result = _9230;\n    float3 param_73 = _9230;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9239 = _612_fa_fog.w > 0.0f;\n    bool _9246;\n    if (!_9239)\n    {\n        _9246 = _612_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _9246 = _9239;\n    }\n    if (_9246)\n    {\n        float3 _9255 = fa_world_pos - _612_fa_camera_pos.xyz;\n        float _9261 = dot(_9255, _612_fa_fog_c.xyz);\n        bool _9265 = _612_fa_fog_c.w > 0.5f;\n        float _9266;\n        if (_9265)\n        {\n            _9266 = _9261;\n        }\n        else\n        {\n            _9266 = length(_9255);\n        }\n        float _9278 = _9266 - _612_fa_fog_b.x;\n        if (_9278 > 0.0f)\n        {\n            float _9287 = _612_fa_fog.w * _9278;\n            float tau = _9287 * _9287;\n            if (_612_fa_fog_b.y > 0.0f)\n            {\n                float _9303;\n                if (_9265)\n                {\n                    _9303 = fa_world_pos.y - (_612_fa_fog_c.y * _9261);\n                }\n                else\n                {\n                    _9303 = _612_fa_camera_pos.y;\n                }\n                float _9324 = lerp(_9303, fa_world_pos.y, clamp(_612_fa_fog_b.x / _9266, 0.0f, 1.0f));\n                float _9328 = fa_world_pos.y - _9324;\n                float _9333 = _9324 - _612_fa_fog_b.z;\n                float _9338 = fa_world_pos.y - _612_fa_fog_b.z;\n                bool _9341 = _9333 <= 0.0f;\n                bool _9342 = !_9341;\n                bool _9348;\n                if (_9342)\n                {\n                    _9348 = _612_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9348 = _9341;\n                }\n                float _9349;\n                if (_9348)\n                {\n                    _9349 = _612_fa_fog_b.y;\n                }\n                else\n                {\n                    _9349 = _612_fa_fog_b.y * exp(-min(_612_fa_fog_b.w * _9333, 80.0f));\n                }\n                bool _9376;\n                if (_9342)\n                {\n                    _9376 = _612_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9376 = _9341;\n                }\n                float _9377;\n                if (_9376)\n                {\n                    _9377 = _612_fa_fog_b.y * _9333;\n                }\n                else\n                {\n                    _9377 = (_612_fa_fog_b.y * (1.0f - exp(-min(_612_fa_fog_b.w * _9333, 80.0f)))) / _612_fa_fog_b.w;\n                }\n                bool _9402 = _9338 <= 0.0f;\n                bool _9409;\n                if (!_9402)\n                {\n                    _9409 = _612_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9409 = _9402;\n                }\n                float _9410;\n                if (_9409)\n                {\n                    _9410 = _612_fa_fog_b.y * _9338;\n                }\n                else\n                {\n                    _9410 = (_612_fa_fog_b.y * (1.0f - exp(-min(_612_fa_fog_b.w * _9338, 80.0f)))) / _612_fa_fog_b.w;\n                }\n                float _9437;\n                if (abs(_9328) < 0.001000000047497451305389404296875f)\n                {\n                    _9437 = _9349;\n                }\n                else\n                {\n                    _9437 = (_9410 - _9377) / _9328;\n                }\n                tau += (_9278 * max(_9437, 0.0f));\n            }\n            result = lerp(result, _612_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9473 = 1.0f - fa_tr_blend;\n        result /= _9473.xxx;\n        _9526 *= _9473;\n    }\n    fa_frag_color = float4(result, _9526);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_612",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2355",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8816",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _390 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _390;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_397, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4850[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _612_fa_camera_pos : packoffset(c0);\n    float4 _612_fa_ambient : packoffset(c1);\n    float4 _612_fa_base_color : packoffset(c2);\n    float4 _612_fa_emissive : packoffset(c3);\n    float4 _612_fa_model_emissive : packoffset(c4);\n    float4 _612_fa_pbr : packoffset(c5);\n    float4 _612_fa_maps : packoffset(c6);\n    float4 _612_fa_fog : packoffset(c7);\n    float4 _612_fa_fog_b : packoffset(c8);\n    float4 _612_fa_fog_c : packoffset(c9);\n    float4 _612_fa_counts : packoffset(c10);\n    float4 _612_fa_env_sky : packoffset(c11);\n    float4 _612_fa_env_horizon : packoffset(c12);\n    float4 _612_fa_time : packoffset(c13);\n    float4 _612_fa_cl_vpx : packoffset(c14);\n    float4 _612_fa_cl_vpy : packoffset(c15);\n    float4 _612_fa_cl_vpw : packoffset(c16);\n    float4 _612_fa_cl_fwd : packoffset(c17);\n    float4 _612_fa_cl_grid : packoffset(c18);\n    float4 _612_fa_cl_info : packoffset(c19);\n    float4 _612_fa_layers_a : packoffset(c20);\n    float4 _612_fa_layers_b : packoffset(c21);\n    float4 _612_fa_layers_c : packoffset(c22);\n    float4 _612_fa_layers_d : packoffset(c23);\n    float4 _612_fa_ct_a : packoffset(c24);\n    float4 _612_fa_ct_b : packoffset(c25);\n    float4 _612_fa_ct_vpx : packoffset(c26);\n    float4 _612_fa_ct_vpy : packoffset(c27);\n    float4 _612_fa_ct_vpw : packoffset(c28);\n    float4 _612_fa_ct_fwd : packoffset(c29);\n    float4 _612_fa_tr_a : packoffset(c30);\n    float4 _612_fa_tr_b : packoffset(c31);\n    float4 _612_fa_probe_sh[9] : packoffset(c32);\n    float4 _612_fa_atlas : packoffset(c41);\n    float4 _612_fa_rpa_tile : packoffset(c42);\n    float4 _612_fa_rpa_pos : packoffset(c43);\n    float4 _612_fa_rpa_bx : packoffset(c44);\n    float4 _612_fa_rpa_by : packoffset(c45);\n    float4 _612_fa_rpa_bz : packoffset(c46);\n    float4 _612_fa_rpb_tile : packoffset(c47);\n    float4 _612_fa_rpb_pos : packoffset(c48);\n    float4 _612_fa_rpb_bx : packoffset(c49);\n    float4 _612_fa_rpb_by : packoffset(c50);\n    float4 _612_fa_rpb_bz : packoffset(c51);\n    float4 _612_fa_gi : packoffset(c52);\n    float4 _612_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2355_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2355_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2355_fa_shadow_info[4] : packoffset(c20);\n    float4 _2355_fa_shadow_split : packoffset(c24);\n    float4 _2355_fa_shadow_cfg : packoffset(c25);\n    float4 _2355_fa_shadow_bias : packoffset(c26);\n    float4 _2355_fa_shadow_eye : packoffset(c27);\n    float4 _2355_fa_shadow_fwd : packoffset(c28);\n    float4 _2355_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _8816_alphaCutoff : packoffset(c0);\n    float _8816_fa_pad0 : packoffset(c0.y);\n    float _8816_fa_pad1 : packoffset(c0.z);\n    float _8816_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1637 = _612_fa_cl_info.x < 0.0f;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = _612_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    bool _1652;\n    if (!_1644)\n    {\n        _1652 = _612_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1652 = _1644;\n    }\n    bool _1659;\n    if (!_1652)\n    {\n        _1659 = _612_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1659 = _1652;\n    }\n    bool _1666;\n    if (!_1659)\n    {\n        _1666 = _612_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1666 = _1659;\n    }\n    if (_1666)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1676 = float4(world_pos, 1.0f);\n    float _1682 = dot(_612_fa_cl_vpw, _1676);\n    if (!(_1682 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1704 = float2(dot(_612_fa_cl_vpx, _1676), dot(_612_fa_cl_vpy, _1676)) / _1682.xx;\n    int _1708 = int(_612_fa_cl_grid.x);\n    int _1712 = int(_612_fa_cl_grid.y);\n    int param = (int(_612_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_612_fa_cl_fwd.xyz, world_pos) + _612_fa_cl_fwd.w, _612_fa_cl_grid.w) / _612_fa_cl_grid.w) * _612_fa_cl_grid.z)), 0, int(_612_fa_cl_info.y) - 1) * _1712) + clamp(int(floor(((_1704.y * 0.5f) + 0.5f) * _612_fa_cl_grid.y)), 0, _1712 - 1)) * _1708)) + clamp(int(floor(((_1704.x * 0.5f) + 0.5f) * _612_fa_cl_grid.x)), 0, _1708 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1788 = fa_cluster_texel(param);\n    return int2(int(_1788.x), int(_1788.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _6484 = dot(_612_fa_ct_fwd.xyz, world_pos) + _612_fa_ct_fwd.w;\n    float _6487 = fwidth(_6484);\n    bool _6490 = _612_fa_ct_b.y > 0.5f;\n    bool _6497;\n    if (!_6490)\n    {\n        _6497 = _612_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _6497 = _6490;\n    }\n    if (_6497)\n    {\n        fa_rt_slope = min(1.5f * _6487, 0.100000001490116119384765625f * _6484);\n    }\n    fa_cl_ndir = int(_612_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6513 = fa_cluster_lookup(param);\n    fa_cl_slot = _6513.x;\n    fa_cl_local = _6513.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7683 = fa_linear_to_srgb(param);\n        c = _7683;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7691 = fa_srgb_to_linear(param_1);\n            c = _7691;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _544;\n    if (i.front_facing)\n    {\n        _544 = i.world_normal;\n    }\n    else\n    {\n        _544 = -i.world_normal;\n    }\n    float3 _568 = normalize(i.world_tangent.xyz - (_544 * dot(_544, i.world_tangent.xyz)));\n    float3 _595 = normalize(((_568 * m.x) + ((cross(_544, _568) * i.world_tangent.w) * m.y)) + (_544 * m.z));\n    float3 _598;\n    if (i.front_facing)\n    {\n        _598 = _595;\n    }\n    else\n    {\n        _598 = -_595;\n    }\n    return _598;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w);\n    float param = _612_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7723 = fa_tex_fix(param_2, param_3);\n    float4 _10105 = base_t;\n    _10105.x = _7723.x;\n    _10105.y = _7723.y;\n    _10105.z = _7723.z;\n    base_t = _10105;\n    float4 _7737 = (_10105 * _612_fa_base_color) * i.vertex_color;\n    float3 _9855 = i.world_normal;\n    if (_612_fa_maps.z > 0.5f)\n    {\n        float param_4 = _612_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7771 = fa_tex_fix(param_6, param_7);\n        float3 _7774 = (_7771 * 2.0f) - 1.0f.xxx;\n        float2 _7779 = _7774.xy * _612_fa_maps.x;\n        float3 _10113 = _7774;\n        _10113.x = _7779.x;\n        _10113.y = _7779.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _10113;\n        _9855 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w);\n    float param_10 = _612_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7809 = fa_tex_fix(param_12, param_13);\n    float4 _10116 = mrt;\n    _10116.x = _7809.x;\n    _10116.y = _7809.y;\n    _10116.z = _7809.z;\n    mrt = _10116;\n    float4 _7839 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w);\n    float param_14 = _612_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7839.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7850 = fa_tex_fix(param_16, param_17);\n    float param_18 = _612_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _612_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7882 = fa_tex_fix(param_20, param_21);\n    float _9860 = _612_fa_layers_a.x;\n    float _9861 = _612_fa_layers_a.y;\n    float _9864 = _612_fa_layers_a.z;\n    float _9863 = _612_fa_layers_b.w;\n    float _9866 = _612_fa_layers_c.x;\n    if (_612_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_612_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9860 *= _7850.y;\n            _9861 *= _7850.z;\n            _9863 *= _7839.w;\n        }\n        if (_612_fa_layers_c.z > 1.5f)\n        {\n            _9864 *= mrt.x;\n            _9866 *= mrt.w;\n        }\n    }\n    Surface _9893 = { _7737.xyz, _7737.w, _9855, clamp(_612_fa_pbr.x * _7809.z, 0.0f, 1.0f), clamp(_612_fa_pbr.y * _7809.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_612_fa_maps.y * (_7850.x - 1.0f)), _612_fa_emissive.xyz + (_612_fa_model_emissive.xyz * _7882), _9860, _9861, _612_fa_layers_b.xyz, _9863, _9864, _612_fa_layers_a.w, _9866, _612_fa_layers_c.y, _612_fa_layers_d.xyz, _612_fa_tr_a.x, _612_fa_tr_a.y, _612_fa_tr_b.xyz, _612_fa_tr_a.z };\n    return _9893;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1868 = rect.zw - rect.xy;\n    float2 _1872 = _1868 * atlas;\n    float2 _1876 = ddx * _1872;\n    float2 _1880 = ddy * _1872;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1868), clamp(0.5f * log2(max(max(dot(_1876, _1876), dot(_1880, _1880)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1913 = _612_fa_counts.y < 0.5f;\n    bool _1920;\n    if (!_1913)\n    {\n        _1920 = _612_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1920 = _1913;\n    }\n    if (_1920)\n    {\n        return;\n    }\n    float3 _1926 = ddx(world_pos);\n    float3 _1929 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1933 = fa_cluster_texel(param);\n    int _1937 = int(_1933.w);\n    if (_1937 < 1)\n    {\n        return;\n    }\n    int _1947 = int(_612_fa_counts.y + 0.5f);\n    int param_1 = _1947;\n    float4 _1951 = fa_light_texel(param_1);\n    float2 _1954 = _1951.yz;\n    int _1958 = int(_1951.w);\n    int param_2 = _1947 + 1;\n    float4 _1963 = fa_light_texel(param_2);\n    float _1964 = _1963.x;\n    int _1970 = int(_612_fa_counts.w + 0.5f) - 1;\n    int _1974 = int(_1933.z);\n    float3 _2239;\n    for (int k = 0; k < _1937; k++)\n    {\n        int _1987 = _1974 + k;\n        int param_3 = _1958 + (_1987 >> 2);\n        int _2004 = (_1947 + 2) + (int(fa_light_texel(param_3)[_1987 & 3]) * 7);\n        int param_4 = _2004 + 6;\n        float4 _2009 = fa_light_texel(param_4);\n        if (((int(_2009.w + 0.5f) >> _1970) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2004;\n        float4 _2024 = fa_light_texel(param_5);\n        int param_6 = _2004 + 1;\n        float4 _2029 = fa_light_texel(param_6);\n        int param_7 = _2004 + 2;\n        float4 _2034 = fa_light_texel(param_7);\n        float3 _2037 = _2024.xyz;\n        float _2042 = dot(_2037, world_pos) + _2024.w;\n        float3 _2044 = _2029.xyz;\n        float _2049 = dot(_2044, world_pos) + _2029.w;\n        float3 _2051 = _2034.xyz;\n        float _2056 = dot(_2051, world_pos) + _2034.w;\n        bool _2061 = abs(_2042) > 0.5f;\n        bool _2069;\n        if (!_2061)\n        {\n            _2069 = abs(_2049) > 0.5f;\n        }\n        else\n        {\n            _2069 = _2061;\n        }\n        bool _2077;\n        if (!_2069)\n        {\n            _2077 = abs(_2056) > 0.5f;\n        }\n        else\n        {\n            _2077 = _2069;\n        }\n        if (_2077)\n        {\n            continue;\n        }\n        float _2092 = clamp(dot(geo_normal, normalize(_2051)) * _2009.z, 0.0f, 1.0f);\n        if (_2092 <= 0.0f)\n        {\n            continue;\n        }\n        float _2112 = (clamp((0.5f - abs(_2056)) * 10.0f, 0.0f, 1.0f) * _2092) * _2009.x;\n        float2 _2120 = float2(_2042 + 0.5f, 0.5f - _2049);\n        float2 _2130 = float2(dot(_2037, _1926), dot(_2044, _1926));\n        float2 _2140 = float2(dot(_2037, _1929), dot(_2044, _1929));\n        int param_8 = _2004 + 5;\n        float4 _2145 = fa_light_texel(param_8);\n        int param_9 = _2004 + 3;\n        float4 _2150 = fa_light_texel(param_9);\n        int param_10 = _2004 + 4;\n        float4 _2155 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2145.xyz;\n        bool _2165 = _2150.z > _2150.x;\n        if (_2165)\n        {\n            float4 param_11 = _2150;\n            float2 param_12 = _2120;\n            float2 param_13 = _1954;\n            float2 param_14 = _2130;\n            float2 param_15 = _2140;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1964 > 0.5f) && (_1964 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2191 = fa_dc_to_linear(param_16);\n                float4 _9943 = tx;\n                _9943.x = _2191.x;\n                _9943.y = _2191.y;\n                _9943.z = _2191.z;\n                tx = _9943;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2112 * tex_a) * _2145.w, 0.0f, 1.0f).xxx);\n        if (_2155.z > _2155.x)\n        {\n            float4 param_17 = _2155;\n            float2 param_18 = _2120;\n            float2 param_19 = _1954;\n            float2 param_20 = _2130;\n            float2 param_21 = _2140;\n            float4 _2235 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1964 > 1.5f)\n            {\n                float3 param_22 = _2235.xyz;\n                float3 _2245 = fa_dc_to_srgb(param_22);\n                _2239 = _2245;\n            }\n            else\n            {\n                _2239 = _2235.xyz;\n            }\n            float3 _2254 = (_2239 * 2.0f) - 1.0f.xxx;\n            float2 _2259 = _2254.xy * _2009.y;\n            float3 _2281 = (normalize(_2037) * _2259.x) + (normalize(_2044) * _2259.y);\n            float3 _2284 = normalize(normal);\n            normal = normalize(lerp(_2284, normalize((_2284 * max(_2254.z, 0.0500000007450580596923828125f)) + (_2281 - (_2284 * dot(_2284, _2281)))), clamp(_2112 * (_2165 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_612_fa_gi.w != 0.0f)\n    {\n        float _633 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _636;\n        if (_612_fa_gi.w > 0.0f)\n        {\n            _636 = _633 >= _612_fa_gi.w;\n        }\n        else\n        {\n            _636 = _633 < (-_612_fa_gi.w);\n        }\n        if (_636)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4775 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4783 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4786 = int(_4775);\n    int _4789 = int(_4783);\n    float _4799 = _4783 - float(_4789);\n    int _4854 = (_4786 * 9) + _4789;\n    int _4874 = ((_4786 + 1) * 9) + _4789;\n    return lerp(lerp(_4850[_4854], _4850[_4854 + 1], _4799), lerp(_4850[_4874], _4850[_4874 + 1], _4799), _4775 - float(_4786));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9778 = false;\n    float _9779 = 1.0f;\n    float _9780 = 1.0f;\n    float _9781 = 1.0f;\n    float _9782 = 0.0f;\n    float _9783 = 0.0f;\n    float _9784 = 0.0f;\n    float _9785 = 0.0f;\n    float _9787 = 1.0f;\n    bool _9788 = false;\n    float3 _9789 = 0.0f.xxx;\n    float _9790 = 1.0f;\n    float _9791 = 1.0f;\n    float _9792 = 1.0f;\n    float _9793 = 0.0f;\n    float _9794 = 0.0f;\n    float3 _9795 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9796 = float3(0.0f, 0.0f, 1.0f);\n    float _9797 = 1.0f;\n    float _9798 = 1.0f;\n    float _4925 = clamp(s.specular, 0.0f, 1.0f);\n    float _4929 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4934 = (_4925 != 1.0f) || (_4929 != 1.5f);\n    bool _4943;\n    if (!_4934)\n    {\n        _4943 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4943 = _4934;\n    }\n    if (_4943)\n    {\n        float _4951 = (_4929 - 1.0f) / (_4929 + 1.0f);\n        f0 = lerp(min((_4951 * _4951).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4925, s.albedo, metallic.xxx);\n        _9779 = lerp(_4925, 1.0f, metallic);\n        _9778 = true;\n    }\n    float _4978 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4978 > 0.0f)\n    {\n        float _4986 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9782 = _4978;\n        _9783 = _4986;\n        float _4993 = _4986 * _4986;\n        _9784 = _4993;\n        _9785 = _4993 * _4993;\n        float _5005 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9787 = _5005;\n        _9780 = 1.0f - (_4978 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _5005, 0.0f, 1.0f), 5.0f))));\n        _9778 = true;\n    }\n    float3 _5024 = max(s.sheen_color, 0.0f.xxx);\n    float _5033 = max(_5024.x, max(_5024.y, _5024.z));\n    if (_5033 > 0.0f)\n    {\n        float _5041 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9788 = true;\n        _9789 = _5024;\n        _9790 = _5041;\n        _9791 = _5041 * _5041;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _5041;\n        float _5058 = fa_sheen_albedo(param, param_1);\n        _9793 = _5058;\n        _9792 = 1.0f - min(_5033 * _5058, 1.0f);\n        _9778 = true;\n    }\n    _9781 = _9780 * _9792;\n    float _5077 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_5077 != 0.0f)\n    {\n        float3 _5092 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _5092;\n        if (dot(_5092, _5092) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _5104 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_5104.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _5104.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _5104.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _5108 = t;\n        float3 _5109 = normalize(_5108);\n        t = _5109;\n        float3 _5134 = normalize((_5109 * cos(s.anisotropy_rotation)) + ((cross(n, _5109) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9795 = _5134;\n        _9796 = cross(n, _5134);\n        float _5144 = roughness * roughness;\n        float _5150 = lerp(_5144, 1.0f, _5077 * _5077);\n        bool _5152 = _5077 > 0.0f;\n        _9797 = _5152 ? _5150 : _5144;\n        _9798 = _5152 ? _5144 : _5150;\n        _9794 = _5077;\n        _9778 = true;\n    }\n    FaLayers _9820 = { _9778, _9779, _9780, _9781, _9782, _9783, _9784, _9785, i.world_normal, _9787, _9788, _9789, _9790, _9791, _9792, _9793, _9794, _9795, _9796, _9797, _9798 };\n    return _9820;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _4005_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _4005_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_612_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3946 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3946;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4557 = (1.0f - _612_fa_rpa_tile.w) - _612_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4562 = _612_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4557 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4562)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _612_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4557;\n            }\n        }\n        else\n        {\n            amb = _612_fa_ambient.xyz * _4557;\n        }\n    }\n    bool _4612 = _612_fa_rpa_tile.w > 0.0f;\n    if (_4612)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _612_fa_rpa_tile.xy;\n            float param_4 = _612_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _612_fa_rpa_tile.w);\n        }\n    }\n    bool _4643 = _612_fa_rpb_tile.w > 0.0f;\n    if (_4643)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _612_fa_rpb_tile.xy;\n            float param_7 = _612_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _612_fa_rpb_tile.w);\n        }\n    }\n    if ((_4562 || _4612) || _4643)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3966 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3969 = _3966.x;\n    float _3971 = _3966.z;\n    float2 e = float2(_3969, _3971);\n    if (_3966.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3971)) * ((_3969 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3969)) * ((_3971 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7992 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7997 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _8002 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _8007 = fa_light_texel(param_3);\n    bool _8010 = _8007.z < 0.5f;\n    bool _8018;\n    if (!_8010)\n    {\n        _8018 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _8018 = _8010;\n    }\n    if (_8018)\n    {\n        return 0.0f.xxx;\n    }\n    float _8025 = max(_7992.w, 9.9999997473787516355514526367188e-05f);\n    float3 _8028 = _7997.xyz;\n    float3 _8032 = _7992.xyz;\n    float3 _8036 = (fa_world_pos - _8032) / _8025.xxx;\n    float3 _8045 = min(_8036 + 0.5f.xxx, (_8028 - 0.5f.xxx) - _8036);\n    float _8054 = min(_8045.x, min(_8045.y, _8045.z));\n    if (!(_8054 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _8069 = _8028 - 1.0f.xxx;\n    float3 _8070 = clamp(_8036, 0.0f.xxx, _8069);\n    float3 _8078 = min(floor(_8070), max(_8028 - 2.0f.xxx, 0.0f.xxx));\n    float3 _8082 = _8070 - _8078;\n    float3 _8093 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _8025));\n    int _8098 = int(_8002.y + 0.5f);\n    float _8103 = 0.3257350027561187744140625f * n.y;\n    float _8107 = 0.3257350027561187744140625f * n.z;\n    float _8111 = 0.3257350027561187744140625f * n.x;\n    float _8118 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _8125 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _8134 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _8141 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _8154 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _8161 = 8 + int(_8007.w);\n    float _8188;\n    float _8201;\n    float _8215;\n    for (int k = 0; k < _8161; k++)\n    {\n        float _8174 = float(k & 1);\n        float _8178 = float((k >> 1) & 1);\n        float _8182 = float((k >> 2) & 1);\n        if (_8174 > 0.5f)\n        {\n            _8188 = _8082.x;\n        }\n        else\n        {\n            _8188 = 1.0f - _8082.x;\n        }\n        if (_8178 > 0.5f)\n        {\n            _8201 = _8082.y;\n        }\n        else\n        {\n            _8201 = 1.0f - _8082.y;\n        }\n        if (_8182 > 0.5f)\n        {\n            _8215 = _8082.z;\n        }\n        else\n        {\n            _8215 = 1.0f - _8082.z;\n        }\n        float _8225 = (_8188 * _8201) * _8215;\n        if (!(_8225 > 0.0f))\n        {\n            continue;\n        }\n        float3 _8238 = min(_8078 + float3(_8174, _8178, _8182), _8069);\n        int _8258 = int(((_8002.x + _8238.x) + (_7997.x * (_8238.y + (_7997.y * _8238.z)))) + 0.5f);\n        float2 _8273 = float2(float(_8258 % _8098) * 10.0f, 1024.0f + (float(_8258 / _8098) * 11.0f));\n        float2 param_4 = _8273 + float2(9.5f, 10.5f);\n        float4 _8281 = fa_gi_fetch(param_4);\n        bool _8284 = _8281.y < 0.5f;\n        bool _8293;\n        if (!_8284)\n        {\n            _8293 = _8281.x > _8007.y;\n        }\n        else\n        {\n            _8293 = _8284;\n        }\n        if (_8293)\n        {\n            continue;\n        }\n        float3 _8305 = _8093 - (_8032 + (_8238 * _8025));\n        float _8308 = length(_8305);\n        float3 _8314 = _8305 / max(_8308, 9.9999997473787516355514526367188e-05f).xxx;\n        float _8324 = max(9.9999997473787516355514526367188e-05f, (dot(-_8314, n) + 1.0f) * 0.5f);\n        float w = _8225 * (_8324 * _8324);\n        float3 param_5 = _8314;\n        float2 param_6 = (_8273 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _8343 = fa_gi_fetch(param_6);\n        float _8350 = _8308 / max(_8002.z, 9.9999997473787516355514526367188e-05f);\n        float _8353 = _8343.x;\n        if (_8350 > _8353)\n        {\n            float _8366 = max(_8343.y - (_8353 * _8353), 0.0f);\n            float _8371 = _8350 - _8353;\n            float _8380 = _8366 / max(_8366 + (_8371 * _8371), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8380 * _8380) * _8380);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _8273 + float2(0.5f, 10.5f);\n        float2 param_8 = _8273 + float2(1.5f, 10.5f);\n        float2 param_9 = _8273 + float2(2.5f, 10.5f);\n        float2 param_10 = _8273 + float2(3.5f, 10.5f);\n        float2 param_11 = _8273 + float2(4.5f, 10.5f);\n        float2 param_12 = _8273 + float2(5.5f, 10.5f);\n        float2 param_13 = _8273 + float2(6.5f, 10.5f);\n        float2 param_14 = _8273 + float2(7.5f, 10.5f);\n        float2 param_15 = _8273 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _8103)) + (fa_gi_fetch(param_9).xyz * _8107)) + (fa_gi_fetch(param_10).xyz * _8111)) + (fa_gi_fetch(param_11).xyz * _8118)) + (fa_gi_fetch(param_12).xyz * _8125)) + (fa_gi_fetch(param_13).xyz * _8134)) + (fa_gi_fetch(param_14).xyz * _8141)) + (fa_gi_fetch(param_15).xyz * _8154)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_8054 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8504;\n    if (_612_fa_gi.z > 0.5f)\n    {\n        _8504 = _8007.x;\n    }\n    else\n    {\n        _8504 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_8002.w * _8504);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8528 = normalize(_612_fa_camera_pos.xyz - fa_world_pos);\n    int _8533 = int(_612_fa_gi.x + 0.5f);\n    int _8538 = int(_612_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8538) && (k < 8); k++)\n    {\n        int param = _8533 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8528;\n        float3 _8563 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8568 = param_3 * left;\n        acc += (_8563 * _8568);\n        left -= _8568;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_612_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8597 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8597;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_612_fa_gi_px.x > 0.5f)\n    {\n        float4 _8639 = float4(fa_world_pos, 1.0f);\n        float2 _8658 = float2(dot(_612_fa_ct_vpx, _8639), dot(_612_fa_ct_vpy, _8639)) / max(dot(_612_fa_ct_vpw, _8639), 9.9999997473787516355514526367188e-05f).xx;\n        float _8667;\n        if (_612_fa_ct_a.y > 0.5f)\n        {\n            _8667 = (_8658.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _8667 = 0.5f - (_8658.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_8658.x * 0.5f) + 0.5f, _8667) * _612_fa_ct_a.zw), int2(0, 0), int2(_612_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_612_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _612_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_612_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_612_fa_cl_info.x) + int(_612_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_612_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6454;\n    if (fa_lm.z > 0.5f)\n    {\n        _6454 = 0.0f;\n    }\n    else\n    {\n        _6454 = 1.0f - clamp(_612_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6465 = _6454 < 1.0f;\n    bool _6471;\n    if (_6465)\n    {\n        int param = li;\n        _6471 = fa_light_baked(param);\n    }\n    else\n    {\n        _6471 = _6465;\n    }\n    return _6471 ? _6454 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _767_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _767_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _886 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _899 = (c - (ru * hx)) - p;\n        float3 _905 = ru * (2.0f * hx);\n        float _911 = max(dot(_905, _905), 9.9999999392252902907785028219223e-09f);\n        float _915 = dot(_899, _905);\n        float t = clamp((-_915) / _911, 0.0f, 1.0f);\n        if (_886)\n        {\n            float _930 = dot(r, _905);\n            float _936 = _911 - (_930 * _930);\n            if (abs(_936) > (9.9999997473787516355514526367188e-06f * _911))\n            {\n                t = clamp(((dot(r, _899) * _930) - _915) / _936, 0.0f, 1.0f);\n            }\n        }\n        return (p + _899) + (_905 * t);\n    }\n    float3 q = p;\n    float _968 = dot(r, axis);\n    bool _976;\n    if (_886)\n    {\n        _976 = abs(_968) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _976 = _886;\n    }\n    if (_976)\n    {\n        float _986 = dot(c - p, axis) / _968;\n        if (_986 > 0.0f)\n        {\n            q = p + (r * _986);\n        }\n    }\n    float3 _999 = q - c;\n    float2 xy = float2(dot(_999, ru), dot(_999, uu));\n    if (shape > 0.5f)\n    {\n        float _1014 = length(xy);\n        if (_1014 > hx)\n        {\n            xy *= (hx / _1014);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _653 = abs(d);\n    float _655 = _653.x;\n    float _657 = _653.y;\n    bool _658 = _655 >= _657;\n    bool _666;\n    if (_658)\n    {\n        _666 = _655 >= _653.z;\n    }\n    else\n    {\n        _666 = _658;\n    }\n    int _667;\n    if (_666)\n    {\n        _667 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _681;\n        if (_657 >= _653.z)\n        {\n            _681 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _681 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _667 = _681;\n    }\n    return _667;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _806 = dot(d, right);\n    float _810 = dot(d, up);\n    float _821;\n    if (((_806 * _806) + (_810 * _810)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _821 = atan2(_810, _806) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _821 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_821 - floor(_821)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1052 = fa_light_base(param);\n    bool _1056 = _612_fa_ambient.w > 4.5f;\n    int param_1 = _1052;\n    float4 _1060 = fa_light_texel(param_1);\n    int param_2 = _1052 + 1;\n    float4 _1065 = fa_light_texel(param_2);\n    float _1068 = _1065.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1080 = _1056 && (_1068 > 2.5f);\n    fa_light_is_area = _1080;\n    bool _1082 = _1068 < 0.5f;\n    float3 l;\n    if (_1082)\n    {\n        l = normalize(_1060.xyz);\n        if (_1056)\n        {\n            int param_3 = _1052 + 6;\n            float4 _1096 = fa_light_texel(param_3);\n            if (_1096.z > 0.5f)\n            {\n                int param_4 = _1052 + 4;\n                float4 _1106 = fa_light_texel(param_4);\n                int param_5 = _1052 + 5;\n                float4 _1111 = fa_light_texel(param_5);\n                float2 param_6 = _1096.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1106.xyz) * _1106.w, (-dot(world_pos, _1111.xyz)) * _1111.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1141 = _1060.xyz;\n        float3 _1143 = _1141 - world_pos;\n        float3 to_light = _1143;\n        float _1146 = length(_1143);\n        float reach = _1146;\n        bool front = true;\n        if (_1080)\n        {\n            int param_8 = _1052 + 7;\n            reach = max(_1146 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1052 + 4;\n            float4 _1170 = fa_light_texel(param_9);\n            int param_10 = _1052 + 5;\n            float4 _1175 = fa_light_texel(param_10);\n            int param_11 = _1052 + 6;\n            float4 _1180 = fa_light_texel(param_11);\n            float _1181 = _1180.w;\n            int param_12 = _1052 + 2;\n            float3 _1188 = normalize(fa_light_texel(param_12).xyz);\n            bool _1190 = _1181 > 1.5f;\n            bool _1198;\n            if (!_1190)\n            {\n                _1198 = dot(_1188, to_light) < 0.0f;\n            }\n            else\n            {\n                _1198 = _1190;\n            }\n            front = _1198;\n            float3 r = 0.0f.xxx;\n            float3 _1207 = _612_fa_camera_pos.xyz - world_pos;\n            bool _1211 = dot(n, n) > 0.5f;\n            bool _1219;\n            if (_1211)\n            {\n                _1219 = dot(_1207, _1207) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1219 = _1211;\n            }\n            if (_1219)\n            {\n                r = reflect(-normalize(_1207), normalize(n));\n            }\n            float3 param_13 = _1141;\n            float3 param_14 = _1188;\n            float3 param_15 = _1170.xyz;\n            float3 param_16 = _1175.xyz;\n            float param_17 = _1170.w;\n            float param_18 = _1175.w;\n            float param_19 = _1181;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1255 = length(to_light);\n        dist = _1255;\n        l = to_light / max(_1255, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1269 = reach / max(_1060.w, 0.001000000047497451305389404296875f);\n        float _1275 = clamp(1.0f - (_1269 * _1269), 0.0f, 1.0f);\n        float _1277;\n        if (front)\n        {\n            _1277 = _1275 * _1275;\n        }\n        else\n        {\n            _1277 = 0.0f;\n        }\n        atten = _1277;\n        bool _1288 = _1068 < 2.5f;\n        if ((_1068 > 1.5f) && _1288)\n        {\n            int param_22 = _1052 + 2;\n            float4 _1296 = fa_light_texel(param_22);\n            float _1306 = _1296.w;\n            int param_23 = _1052 + 3;\n            float4 _1311 = fa_light_texel(param_23);\n            float _1312 = _1311.x;\n            float cos_inner = _1312;\n            if (_1312 > 1.5f)\n            {\n                cos_inner = lerp(_1306, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1306, cos_inner, dot(-l, normalize(_1296.xyz)));\n        }\n        if (_1056 && (_1068 < 1.5f))\n        {\n            int param_24 = _1052 + 6;\n            float4 _1336 = fa_light_texel(param_24);\n            if (_1336.z > 0.5f)\n            {\n                float3 _1344 = -to_light;\n                int param_25 = _1052 + 4;\n                int param_26 = _1052 + 5;\n                float3 _1358 = fa_light_texel(param_25).xyz;\n                float3 _1362 = fa_light_texel(param_26).xyz;\n                float3 _1371 = float3(dot(_1344, _1358), dot(_1344, _1362), dot(_1344, cross(_1358, _1362)));\n                float3 param_27 = _1371;\n                int _1375 = fa_cube_face(param_27);\n                int param_28 = _1375;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1402 = float2(dot(_1371, cross(param_29, param_30)), dot(_1371, param_30)) / max(dot(_1371, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1406 = _1375 / 3;\n                float2 param_31 = _1336.xy + (float2(float(_1375 - (_1406 * 3)), float(_1406)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1402.x), 0.5f - (0.5f * _1402.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1052 + 7;\n            float4 _1436 = fa_light_texel(param_33);\n            if (_1436.z > 0.5f)\n            {\n                int param_34 = _1052 + 2;\n                int param_35 = _1052 + 4;\n                int param_36 = _1052 + 5;\n                float2 param_37 = _1436.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1056 && _1288)\n            {\n                int param_42 = _1052 + 6;\n                float4 _1483 = fa_light_texel(param_42);\n                int param_43 = _1052 + 7;\n                float4 _1488 = fa_light_texel(param_43);\n                bool _1491 = _1483.z > 0.5f;\n                bool _1498;\n                if (!_1491)\n                {\n                    _1498 = _1488.z > 0.5f;\n                }\n                else\n                {\n                    _1498 = _1491;\n                }\n                if (_1498)\n                {\n                    int param_44 = _1052 + 2;\n                    float4 _1505 = fa_light_texel(param_44);\n                    float3 _1509 = normalize(_1505.xyz);\n                    int param_45 = _1052 + 4;\n                    float4 _1514 = fa_light_texel(param_45);\n                    int param_46 = _1052 + 5;\n                    float4 _1519 = fa_light_texel(param_46);\n                    if (_1491)\n                    {\n                        float3 _1527 = -to_light;\n                        float _1534 = _1505.w;\n                        float _1550 = 0.5f / max(dot(_1527, _1509) * (sqrt(max(1.0f - (_1534 * _1534), 0.0f)) / max(_1534, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1483.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1527, _1514.xyz) * _1550), 0.5f - (dot(_1527, _1519.xyz) * _1550));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1488.z > 0.5f)\n                    {\n                        float2 param_49 = _1488.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1509;\n                        float3 param_52 = _1514.xyz;\n                        float3 param_53 = _1519.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9766 = _1065.xyz * atten;\n    if (_1056)\n    {\n        _9766 *= fa_light_tint;\n    }\n    int _1619;\n    if (_1082)\n    {\n        _1619 = 0;\n    }\n    else\n    {\n        _1619 = ((_1068 > 1.5f) && (_1068 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9777 = { l, _9766, atten, 1.0f, dist, _1619 };\n    return _9777;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2345;\n    if (i == 0)\n    {\n        _2345 = _2355_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2361;\n        if (i == 1)\n        {\n            _2361 = _2355_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2369;\n            if (i == 2)\n            {\n                _2369 = _2355_fa_shadow_split.z;\n            }\n            else\n            {\n                _2369 = _2355_fa_shadow_split.w;\n            }\n            _2361 = _2369;\n        }\n        _2345 = _2361;\n    }\n    return _2345;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2402 = fa_shadow_depth(param, param_1);\n    float _2406;\n    if (conv.x < 0.5f)\n    {\n        _2406 = _2402;\n    }\n    else\n    {\n        _2406 = (conv.y * conv.z) / (conv.z - (_2402 * (conv.z - conv.y)));\n    }\n    return _2406;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2452 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2458 = float2(cos(_2452), sin(_2452));\n    float2 dir = _2458;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2467;\n        if (k < 0.0f)\n        {\n            _2467 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2467 = k;\n        }\n        float _2486 = clamp((_2467 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2505 = sqrt((float(i) + 0.5f) * 0.0625f) * _2486;\n            float2 param_3 = uv + (dir * (_2355_fa_shadow_bias.zw * _2505));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2519 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2519 < (zr - (_2505 * plane)))\n            {\n                sum += _2519;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2547 = sum / cnt;\n        float _2557;\n        if (k < 0.0f)\n        {\n            _2557 = (-k) / max(_2547, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2557 = k;\n        }\n        radius = clamp(((max(zr - _2547, 0.0f) * unit) * _2557) / texel_m, 1.5f, 16.0f);\n        dir = _2458;\n    }\n    float lit = 0.0f;\n    int _2583 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2583; i_1++)\n    {\n        float _2602 = sqrt((float(i_1) + 0.5f) / float(_2583)) * radius;\n        float2 param_7 = uv + (dir * (_2355_fa_shadow_bias.zw * _2602));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2602 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2583);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2648 = max(_2355_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2653 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2659 = sqrt(1.0f - (_2653 * _2653));\n    float _2667 = min(_2659 / max(_2653, 0.20000000298023223876953125f), 4.0f);\n    float _2672;\n    if (_2355_fa_shadow_bias.y > 0.0f)\n    {\n        _2672 = _2355_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2672 = 1.5f * _2355_fa_shadow_info[ci].x;\n    }\n    float4 _2697 = mul(float4(world + (n * (_2672 * _2659)), 1.0f), _2355_fa_shadow_mat[ci]);\n    float _2704 = _2697.x;\n    bool _2707 = _2704 < _2355_fa_shadow_rect[ci].x;\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2704 > _2355_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2697.y < _2355_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2697.y > _2355_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2741;\n    if (!_2734)\n    {\n        _2741 = _2697.z > 1.0f;\n    }\n    else\n    {\n        _2741 = _2734;\n    }\n    if (_2741)\n    {\n        return -1.0f;\n    }\n    float _2749;\n    if (_2355_fa_shadow_bias.x > 0.0f)\n    {\n        _2749 = _2355_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2749 = 1.5f * _2355_fa_shadow_info[ci].x;\n    }\n    float2 param = _2697.xy;\n    float4 param_1 = _2355_fa_shadow_rect[ci];\n    float param_2 = _2697.z - ((_2749 * (1.0f + (0.5f * _2667))) / _2648);\n    float param_3 = _2355_fa_shadow_info[ci].x;\n    float param_4 = _2648;\n    float param_5 = _2648 * 0.25f;\n    float param_6 = ((_2355_fa_shadow_info[ci].x * min(_2667, 3.0f)) * 0.5f) / _2648;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2355_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2355_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_612_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3127 = int(_2355_fa_shadow_cfg.x + 0.5f);\n    if (_3127 < 1)\n    {\n        return 1.0f;\n    }\n    float _3142 = dot(world - _2355_fa_shadow_eye.xyz, _2355_fa_shadow_fwd.xyz);\n    int param = _3127 - 1;\n    if (_3142 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3154 = _3127 > 1;\n    bool _3161;\n    if (_3154)\n    {\n        _3161 = _3142 > _2355_fa_shadow_split.x;\n    }\n    else\n    {\n        _3161 = _3154;\n    }\n    if (_3161)\n    {\n        ci = 1;\n    }\n    bool _3165 = _3127 > 2;\n    bool _3172;\n    if (_3165)\n    {\n        _3172 = _3142 > _2355_fa_shadow_split.y;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        ci = 2;\n    }\n    bool _3176 = _3127 > 3;\n    bool _3183;\n    if (_3176)\n    {\n        _3183 = _3142 > _2355_fa_shadow_split.z;\n    }\n    else\n    {\n        _3183 = _3176;\n    }\n    if (_3183)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3194 = min(_3127, 4);\n    float _3235;\n    for (int c = ci; c < _3194; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3214 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3214;\n            break;\n        }\n        if (_3214 < 0.0f)\n        {\n            continue;\n        }\n        s = _3214;\n        ci = c;\n        if (_2355_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3235 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3235 = _2355_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3254 = _2355_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3235, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3142 - (fa_shadow_split_at(param_7) - _3254)) / _3254, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3286;\n        if ((ci + 1) < _3127)\n        {\n            _3286 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3286 = 1.0f;\n        }\n        s = lerp(s, _3286, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3391 = _612_fa_ct_b.y > 0.5f;\n    bool _3397;\n    if (_3391)\n    {\n        _3397 = _612_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3397 = _3391;\n    }\n    if (_3397)\n    {\n        float _3411 = dot(_612_fa_ct_fwd.xyz, fa_world_pos) + _612_fa_ct_fwd.w;\n        float4 _3419 = float4(fa_world_pos, 1.0f);\n        float _3425 = dot(_612_fa_ct_vpw, _3419);\n        if (_3425 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3444 = float2(dot(_612_fa_ct_vpx, _3419), dot(_612_fa_ct_vpy, _3419)) / _3425.xx;\n            float _3449 = (_3444.x * 0.5f) + 0.5f;\n            float _3453;\n            if (_612_fa_ct_a.y > 0.5f)\n            {\n                _3453 = (_3444.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3453 = 0.5f - (_3444.y * 0.5f);\n            }\n            bool _3469 = _3449 >= 0.0f;\n            bool _3475;\n            if (_3469)\n            {\n                _3475 = _3449 < 1.0f;\n            }\n            else\n            {\n                _3475 = _3469;\n            }\n            bool _3481;\n            if (_3475)\n            {\n                _3481 = _3453 >= 0.0f;\n            }\n            else\n            {\n                _3481 = _3475;\n            }\n            bool _3487;\n            if (_3481)\n            {\n                _3487 = _3453 < 1.0f;\n            }\n            else\n            {\n                _3487 = _3481;\n            }\n            if (_3487)\n            {\n                float4 _3513 = fa_screen_tex.Load(int3(clamp(int2(float2(_3449, _3453) * _612_fa_ct_a.zw), int2(0, 0), int2(_612_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3516 = _3513.w > 0.5f;\n                bool _3532;\n                if (_3516)\n                {\n                    _3532 = abs(_3411 - _3513.x) <= (((0.00200000009499490261077880859375f * _3411) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3532 = _3516;\n                }\n                if (_3532)\n                {\n                    float _3538;\n                    if (_612_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3538 = min(_3513.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3538 = _3513.y;\n                    }\n                    return _3538;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2807 = _612_fa_pbr.z < 0.5f;\n    bool _2814;\n    if (!_2807)\n    {\n        _2814 = _2355_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2814 = _2807;\n    }\n    if (_2814)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2355_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2827 = fa_light_texel(param);\n    float _2828 = _2827.x;\n    if (_2828 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2837 = int(_2828 + 0.5f);\n    int param_1 = _2837;\n    float4 _2841 = fa_light_texel(param_1);\n    int param_2 = _2837 + 1;\n    float4 _2846 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2849 = _2841.y;\n    if (_2849 > 0.0f)\n    {\n        float _2866 = 1.0f - smoothstep(0.75f * _2849, _2849, length(world - _2355_fa_shadow_eye.xyz));\n        fade = _2866;\n        if (_2866 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2841.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2890 = (_2837 + 2) + (face * 6);\n    int param_4 = _2890;\n    int param_5 = _2890 + 1;\n    int param_6 = _2890 + 3;\n    float4 _2904 = fa_light_texel(param_6);\n    int param_7 = _2890 + 4;\n    float4 _2909 = fa_light_texel(param_7);\n    int param_8 = _2890 + 5;\n    float4 _2914 = fa_light_texel(param_8);\n    float _2926 = _2914.x * max(dot(_2904, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2931 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2954 = clamp(dot(n, _2904.xyz), -1.0f, 1.0f);\n    float _2973 = min(sqrt(1.0f - (_2954 * _2954)) / max(abs(dot(n, world - lpos)) / max(dot(_2904, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2976 = _2846.y;\n    float _2978;\n    if (_2976 > 0.0f)\n    {\n        _2978 = _2976;\n    }\n    else\n    {\n        _2978 = 1.5f * _2926;\n    }\n    float4 _2998 = float4(world + (n * (_2978 * sqrt(1.0f - (_2931 * _2931)))), 1.0f);\n    float _3002 = dot(_2904, _2998);\n    float _3005 = _2914.y;\n    if (_3002 < _3005)\n    {\n        return 1.0f;\n    }\n    float2 _3020 = float2(dot(fa_light_texel(param_4), _2998), dot(fa_light_texel(param_5), _2998)) / _3002.xx;\n    float _3022 = _3020.x;\n    bool _3025 = _3022 < _2909.x;\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3022 > _2909.z;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3020.y < _2909.y;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    bool _3052;\n    if (!_3043)\n    {\n        _3052 = _3020.y > _2909.w;\n    }\n    else\n    {\n        _3052 = _3043;\n    }\n    if (_3052)\n    {\n        return 1.0f;\n    }\n    float _3058 = _2846.x;\n    float _3060;\n    if (_3058 > 0.0f)\n    {\n        _3060 = _3058;\n    }\n    else\n    {\n        _3060 = 1.5f * _2926;\n    }\n    float2 param_9 = _3020;\n    float4 param_10 = _2909;\n    float param_11 = _3002 - (_3060 * (1.0f + (0.5f * _2973)));\n    float param_12 = _2926;\n    float param_13 = 1.0f;\n    float param_14 = _2914.z * 0.25f;\n    float param_15 = (_2926 * min(_2973, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _3005, _2914.z);\n    int param_17 = int(_2841.z + 0.5f);\n    float param_18 = _2841.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3567 = _612_fa_ct_b.w > 0.5f;\n    bool _3573;\n    if (_3567)\n    {\n        _3573 = _612_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3573 = _3567;\n    }\n    bool _3579;\n    if (_3573)\n    {\n        _3579 = _2355_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3579 = _3573;\n    }\n    if (_3579)\n    {\n        int param = (int(_2355_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3591 = fa_light_texel(param);\n        float _3592 = _3591.z;\n        if (_3592 > 0.5f)\n        {\n            float _3605 = dot(_612_fa_ct_fwd.xyz, world) + _612_fa_ct_fwd.w;\n            float _3611 = ((0.00200000009499490261077880859375f * _3605) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3617 = float4(world, 1.0f);\n            float _3622 = dot(_612_fa_ct_vpw, _3617);\n            if (_3622 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3639 = float2(dot(_612_fa_ct_vpx, _3617), dot(_612_fa_ct_vpy, _3617)) / _3622.xx;\n                float _3644 = (_3639.x * 0.5f) + 0.5f;\n                float _3648;\n                if (_612_fa_ct_a.y > 0.5f)\n                {\n                    _3648 = (_3639.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3648 = 0.5f - (_3639.y * 0.5f);\n                }\n                bool _3664 = _3644 >= 0.0f;\n                bool _3670;\n                if (_3664)\n                {\n                    _3670 = _3644 < 1.0f;\n                }\n                else\n                {\n                    _3670 = _3664;\n                }\n                bool _3676;\n                if (_3670)\n                {\n                    _3676 = _3648 >= 0.0f;\n                }\n                else\n                {\n                    _3676 = _3670;\n                }\n                bool _3682;\n                if (_3676)\n                {\n                    _3682 = _3648 < 1.0f;\n                }\n                else\n                {\n                    _3682 = _3676;\n                }\n                if (_3682)\n                {\n                    int2 _3699 = int2(_612_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3700 = clamp(int2(float2(_3644, _3648) * _612_fa_ct_a.zw), int2(0, 0), _3699);\n                    float _3704;\n                    if (_3592 < 1.5f)\n                    {\n                        _3704 = 1.0f;\n                    }\n                    else\n                    {\n                        _3704 = (_3592 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    int _3726;\n                    int _3732;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3726 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3732 = k - 1;\n                            }\n                            else\n                            {\n                                _3732 = k;\n                            }\n                            _3726 = _3732;\n                        }\n                        float4 _3761 = fa_screen_tex.Load(int3(clamp(_3700 + int2((_3726 % 3) - 1, (_3726 / 3) - 1), int2(0, 0), _3699), 0));\n                        bool _3764 = _3761.w > 0.5f;\n                        bool _3774;\n                        if (_3764)\n                        {\n                            _3774 = abs(_3605 - _3761.x) <= _3611;\n                        }\n                        else\n                        {\n                            _3774 = _3764;\n                        }\n                        if (_3774)\n                        {\n                            best = min(best, mod(floor(_3761.z / _3704), 256.0f) * 0.0039215688593685626983642578125f);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3801;\n                        if (_612_fa_ct_b.z > 0.5f)\n                        {\n                            int param_1 = li;\n                            float3 param_2 = lpos;\n                            float3 param_3 = world;\n                            float3 param_4 = n;\n                            float3 param_5 = l;\n                            _3801 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3801 = best;\n                        }\n                        return _3801;\n                    }\n                }\n            }\n            float _3824;\n            if (_612_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3824 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3824 = 1.0f;\n            }\n            return _3824;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5668 = _612_fa_ct_a.x < 0.5f;\n    bool _5675;\n    if (!_5668)\n    {\n        _5675 = _2355_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5675 = _5668;\n    }\n    if (_5675)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2355_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5688 = fa_light_texel(param);\n    float _5689 = _5688.y;\n    float len = _5689;\n    if (_5689 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5701 = length(world - _612_fa_camera_pos.xyz);\n    float _5710 = 1.0f - smoothstep(0.5f * _612_fa_ct_b.x, _612_fa_ct_b.x, _5701);\n    if (_5710 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5716 = len;\n    float _5719 = min(_5716, 0.89999997615814208984375f * dist);\n    len = _5719;\n    float _5724 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5701);\n    float _5729 = _5724 + (0.5f * _5719);\n    float3 _5735 = world + (gn * _5724);\n    float _5737 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5798;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5752 = (float(k) + _5737) * 0.083333335816860198974609375f;\n        float3 _5760 = _5735 + (l * (_5752 * len));\n        float4 _5766 = float4(_5760, 1.0f);\n        float _5771 = dot(_612_fa_ct_vpw, _5766);\n        if (_5771 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5789 = float2(dot(_612_fa_ct_vpx, _5766), dot(_612_fa_ct_vpy, _5766)) / _5771.xx;\n        float _5793 = _5789.x * 0.5f;\n        float _5794 = _5793 + 0.5f;\n        if (_612_fa_ct_a.y > 0.5f)\n        {\n            _5798 = (_5789.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5798 = 0.5f - (_5789.y * 0.5f);\n        }\n        bool _5814 = _5794 < 0.0f;\n        bool _5821;\n        if (!_5814)\n        {\n            _5821 = _5794 >= 1.0f;\n        }\n        else\n        {\n            _5821 = _5814;\n        }\n        bool _5828;\n        if (!_5821)\n        {\n            _5828 = _5798 < 0.0f;\n        }\n        else\n        {\n            _5828 = _5821;\n        }\n        bool _5835;\n        if (!_5828)\n        {\n            _5835 = _5798 >= 1.0f;\n        }\n        else\n        {\n            _5835 = _5828;\n        }\n        if (_5835)\n        {\n            break;\n        }\n        float4 _5859 = fa_screen_tex.Load(int3(clamp(int2(float2(_5794, _5798) * _612_fa_ct_a.zw), int2(0, 0), int2(_612_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5859.w < 0.5f)\n        {\n            continue;\n        }\n        float _5877 = (dot(_612_fa_ct_fwd.xyz, _5760) + _612_fa_ct_fwd.w) - _5859.x;\n        if ((_5877 > _5724) && (_5877 < _5729))\n        {\n            occ = max(occ, (1.0f - (_5752 * _5752)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5794, 0.5f - _5793), min(_5798, 1.0f - _5798))));\n        }\n    }\n    return 1.0f - (occ * _5710);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6539 = fa_baked_keep(param);\n    if (_6539 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9833 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9833;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6565 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9835 = _6565.color;\n    float _9836 = _6565.attenuation;\n    float _9837 = _6565.shadow;\n    bool _6568 = _6565.type == 0;\n    if (_6568 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6565.direction;\n        float _6579 = fa_shadow_factor(param_5, param_6);\n        _9837 = _6579;\n        _9835 *= _6579;\n    }\n    else\n    {\n        bool _6590 = _6565.type != 0;\n        bool _6596;\n        if (_6590)\n        {\n            _6596 = _9836 > 0.0f;\n        }\n        else\n        {\n            _6596 = _6590;\n        }\n        if (_6596)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6565.direction;\n            float _6615 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9837 = _6615;\n            _9835 *= _6615;\n        }\n    }\n    bool _6625 = _612_fa_ct_a.x > 0.5f;\n    bool _6631;\n    if (_6625)\n    {\n        _6631 = _9836 > 0.0f;\n    }\n    else\n    {\n        _6631 = _6625;\n    }\n    if (_6631)\n    {\n        float _6638;\n        if (_6568)\n        {\n            _6638 = 1000000000.0f;\n        }\n        else\n        {\n            _6638 = _6565._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6565.direction;\n        float param_18 = _6638;\n        float _6656 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9837 *= _6656;\n        _9835 *= _6656;\n    }\n    float _6669 = _9836;\n    float _6670 = _6669 * _6539;\n    _9836 = _6670;\n    float3 _6674 = _9835;\n    float3 _6675 = _6674 * _6539;\n    _9835 = _6675;\n    LightSample _9852 = { _6565.direction, _6675, _6670, _9837, _6565._distance, _6565.type };\n    return _9852;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6709 = v - (n * dot(v, n));\n    float3 t = _6709;\n    float _6713 = dot(_6709, _6709);\n    float l2 = _6713;\n    if (_6713 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6723;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6723 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6723 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6723;\n        l2 = dot(_6723, _6723);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _7110;\n    if ((j == 0) || (j == 7))\n    {\n        _7110 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7120;\n        if ((j == 3) || (j == 4))\n        {\n            _7120 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7120 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7110 = _7120;\n    }\n    float _7141;\n    if ((j == 1) || (j == 2))\n    {\n        _7141 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _7150;\n        if ((j == 5) || (j == 6))\n        {\n            _7150 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _7150 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _7141 = _7150;\n    }\n    return (pc + (ex * _7110)) + (ey * _7141);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6758 = dot(a, a);\n    float _6762 = dot(b, b);\n    if ((_6758 < 1.0000000195414813782625560981111e-24f) || (_6762 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6776 = a * rsqrt(_6758);\n    float3 _6781 = b * rsqrt(_6762);\n    float _6785 = dot(_6776, _6781);\n    float _6788 = abs(_6785);\n    float g = (((((((((((0.0416471660137176513671875f * _6788) - 0.1924748718738555908203125f) * _6788) + 0.4179156124591827392578125f) * _6788) - 0.616057217121124267578125f) * _6788) + 0.777722418308258056640625f) * _6788) - 0.999542415142059326171875f) * _6788) + 1.570791721343994140625f;\n    if (_6785 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6785 * _6785), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6776, _6781) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6845 = a.z > 0.0f;\n    bool _6849 = b.z > 0.0f;\n    if (_6845 && _6849)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6845 != _6849)\n        {\n            float3 _6884 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6884.z = 0.0f;\n            if (_6845)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6884;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6884;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6884;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6884;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6933 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6959 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6985 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _7011 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6933;\n    float3 param_1 = _6959;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6959;\n    float3 param_7 = _6985;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6985;\n    float3 param_13 = _7011;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _7011;\n    float3 param_19 = _6933;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _7179 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _7197;\n    for (int k = 0; k < (2 * _7179); k++)\n    {\n        bool _7194 = k >= _7179;\n        if (_7194)\n        {\n            _7197 = k - _7179;\n        }\n        else\n        {\n            _7197 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_7179 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7243 = 2 * _7197;\n            int param_4 = _7243 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7243 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7243 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _7280 = _7194.xxxx;\n        float4 param_16 = float4(_7280.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _7280.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _7280.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _7280.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _7291 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7194)\n        {\n            float2 _10088 = sum;\n            _10088.y = _10088.y + _7291;\n            sum = _10088;\n        }\n        else\n        {\n            float2 _10091 = sum;\n            _10091.x = _10091.x + _7291;\n            sum = _10091;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7315 = fa_light_base(param);\n    int param_1 = _7315;\n    int param_2 = _7315 + 1;\n    int param_3 = _7315 + 2;\n    int param_4 = _7315 + 4;\n    float4 _7337 = fa_light_texel(param_4);\n    int param_5 = _7315 + 5;\n    float4 _7342 = fa_light_texel(param_5);\n    int param_6 = _7315 + 6;\n    float4 _7347 = fa_light_texel(param_6);\n    float _7348 = _7347.w;\n    float3 _7353 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7355 = _7348 < 1.5f;\n    bool _7362;\n    if (_7355)\n    {\n        _7362 = dot(normalize(fa_light_texel(param_3).xyz), _7353) >= 0.0f;\n    }\n    else\n    {\n        _7362 = _7355;\n    }\n    if (_7362)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7371 = (_7348 > 0.5f) && _7355;\n    float _7375 = _7371 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7378 = _7337.xyz;\n    float _7380 = _7337.w;\n    float3 _7386 = _7342.xyz;\n    float _7388 = _7342.w;\n    float3 up = _7386 * (_7388 * _7375);\n    float _7394;\n    if (_7371)\n    {\n        _7394 = (3.1415927410125732421875f * _7380) * _7380;\n    }\n    else\n    {\n        _7394 = (4.0f * _7380) * _7388;\n    }\n    if (_7348 > 1.5f)\n    {\n        float3 _7420 = cross(_7378, -_7353);\n        float3 perp = _7420;\n        float _7424 = dot(_7420, _7420);\n        float3 _7427;\n        if (_7424 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7427 = perp * rsqrt(_7424);\n        }\n        else\n        {\n            _7427 = _7386;\n        }\n        perp = _7427;\n        up = _7427 * _7388;\n    }\n    float _7448 = max(_7394, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7458 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7458;\n    float3 param_10 = n;\n    float3 param_11 = _7353;\n    float3 param_12 = _7458;\n    float3 param_13 = n;\n    float3 param_14 = _7378 * (_7380 * _7375);\n    float3 param_15 = _7458;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7489 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7489;\n    float2 param_21 = _7489 + float2(64.0f, 0.0f);\n    float4 _7499 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7348;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7511 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7511.x) + (((f0 * _7499.x) + ((f90.xxx - f0) * _7499.y)) * _7511.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_7353, _7353)) + _7448) / _7448) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5405 = 1.0f / alpha;\n    return ((2.0f + _5405) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5405)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5440 = max(dot(L.nc, l), 0.0f);\n    float _5446 = max(dot(L.nc, h), 0.0f);\n    float _5455 = ((_5446 * _5446) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5455) * _5455)) * (0.5f / max(lerp((2.0f * _5440) * L.coat_ndv, _5440 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5440)) * _5440;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7548;\n    if (L.sheen_on)\n    {\n        _7548 = L.sheen_scale;\n    }\n    else\n    {\n        _7548 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7548);\n    float3 _7561 = normalize(l + v);\n    int param = li;\n    float3 _7572 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7581 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7561), 0.0f);\n        float param_3 = _7581;\n        float param_4 = ndv;\n        result += ((L.sheen * _7572) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7581)) * _7581) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7561;\n        float param_8 = max(dot(v, _7561), 0.0f);\n        result += (_7572 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5308 = tdh / at;\n    float _5312 = bdh / ab;\n    float _5324 = ((_5308 * _5308) + (_5312 * _5312)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _5324) * _5324);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5504 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5583 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5583) * _5583);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5504);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5504));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4707 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4710 = _4707.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4710 * _4710, exp2((-9.27999973297119140625f) * ndv)) * _4710) + _4707.y)) + _4707.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _4018;\n    if (lv == 0)\n    {\n        _4018 = 0.0f;\n    }\n    else\n    {\n        _4018 = res + 2.0f;\n    }\n    float _4028;\n    if (lv == 0)\n    {\n        _4028 = 0.0f;\n    }\n    else\n    {\n        _4028 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_4018, _4028)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _4074;\n    if (res > 64.5f)\n    {\n        _4074 = 5.0f;\n    }\n    else\n    {\n        _4074 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _4089 = clamp(rough, 0.0f, 1.0f) * (_4074 - 1.0f);\n    int _4096 = int(min(floor(_4089), _4074 - 2.0f));\n    float _4101 = _4089 - float(_4096);\n    float3 param = d;\n    float2 _4105 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4096;\n    float2 param_4 = _4105;\n    float3 _4115 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4101 < 0.00200000009499490261077880859375f)\n    {\n        return _4115;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4096 + 1;\n    float2 param_8 = _4105;\n    return lerp(_4115, fa_probe_level(param_5, param_6, param_7, param_8), _4101.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _4186 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4193 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4200 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4206 = dot(bx.xyz, d);\n    float _4210 = dot(by.xyz, d);\n    float _4214 = dot(bz.xyz, d);\n    float _4220;\n    if (_4206 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4220 = (1.0f - _4186) / _4206;\n    }\n    else\n    {\n        float _4234;\n        if (_4206 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4234 = ((-1.0f) - _4186) / _4206;\n        }\n        else\n        {\n            _4234 = 1000000015047466219876688855040.0f;\n        }\n        _4220 = _4234;\n    }\n    float tx = _4220;\n    float _4251;\n    if (_4210 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4251 = (1.0f - _4193) / _4210;\n    }\n    else\n    {\n        float _4264;\n        if (_4210 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4264 = ((-1.0f) - _4193) / _4210;\n        }\n        else\n        {\n            _4264 = 1000000015047466219876688855040.0f;\n        }\n        _4251 = _4264;\n    }\n    float ty = _4251;\n    float _4280;\n    if (_4214 > 9.9999999747524270787835121154785e-07f)\n    {\n        _4280 = (1.0f - _4200) / _4214;\n    }\n    else\n    {\n        float _4293;\n        if (_4214 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _4293 = ((-1.0f) - _4200) / _4214;\n        }\n        else\n        {\n            _4293 = 1000000015047466219876688855040.0f;\n        }\n        _4280 = _4293;\n    }\n    float _4305 = tx;\n    float _4308 = (_4305 > 0.0f) ? _4305 : 1000000015047466219876688855040.0f;\n    tx = _4308;\n    float _4309 = ty;\n    float _4312 = (_4309 > 0.0f) ? _4309 : 1000000015047466219876688855040.0f;\n    ty = _4312;\n    float _4322 = min(_4308, min(_4312, (_4280 > 0.0f) ? _4280 : 1000000015047466219876688855040.0f));\n    if (_4322 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4338 = (fa_world_pos + (d * _4322)) - posw.xyz;\n    float3 _4343;\n    if (dot(_4338, _4338) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4343 = normalize(_4338);\n    }\n    else\n    {\n        _4343 = d;\n    }\n    return _4343;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4389 = (1.0f - _612_fa_rpa_tile.w) - _612_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4389 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_612_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _612_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4417 = rough * rough;\n            float _4448 = 0.60000002384185791015625f * _4417;\n            base = lerp(lerp(_612_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_612_fa_env_horizon.xyz, _612_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4417)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4448, 0.0500000007450580596923828125f + _4448, d.y).xxx), ((_612_fa_env_sky.xyz + _612_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4417 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4389;\n    }\n    if (_612_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _612_fa_rpa_tile;\n        float4 param_5 = _612_fa_rpa_pos;\n        float4 param_6 = _612_fa_rpa_bx;\n        float4 param_7 = _612_fa_rpa_by;\n        float4 param_8 = _612_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4507 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4507 * _612_fa_rpa_tile.w);\n    }\n    if (_612_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _612_fa_rpb_tile;\n        float4 param_12 = _612_fa_rpb_pos;\n        float4 param_13 = _612_fa_rpb_bx;\n        float4 param_14 = _612_fa_rpb_by;\n        float4 param_15 = _612_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4539 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4539 * _612_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _5185;\n        if (L.aniso >= 0.0f)\n        {\n            _5185 = L.b;\n        }\n        else\n        {\n            _5185 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_5185, v), _5185), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5221 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _5221.x) + (L.f90.xxx * _5221.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _5279 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _5279.x) + _5279.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4749 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4749.x) + _4749.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_612_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_612_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5981 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5985 = fa_xm_origin(param_1);\n    float2 _5991 = (uv * _5981) - 0.5f.xx;\n    float2 _5994 = frac(_5991);\n    float2 _5997 = floor(_5991);\n    float2 param_2 = _5981;\n    float2 param_3 = _5985;\n    float2 param_4 = _5997;\n    float2 param_5 = _5981;\n    float2 param_6 = _5985;\n    float2 param_7 = _5997 + float2(1.0f, 0.0f);\n    float2 param_8 = _5981;\n    float2 param_9 = _5985;\n    float2 param_10 = _5997 + float2(0.0f, 1.0f);\n    float2 param_11 = _5981;\n    float2 param_12 = _5985;\n    float2 param_13 = _5997 + 1.0f.xx;\n    float3 _6039 = _5994.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6039), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6039), _5994.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _6058 = max(_612_fa_tr_b.w - 1.0f, 0.0f);\n    float _6062 = clamp(lod, 0.0f, _6058);\n    int _6066 = int(floor(_6062));\n    int param = _6066;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _6076 = float(_6066);\n    float _6077 = _6062 - _6076;\n    bool _6079 = _6077 > 0.001000000047497451305389404296875f;\n    bool _6086;\n    if (_6079)\n    {\n        _6086 = _6076 < _6058;\n    }\n    else\n    {\n        _6086 = _6079;\n    }\n    if (_6086)\n    {\n        int param_2 = _6066 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _6077.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _6112 = fa_env_brdf(param, param_1);\n    float3 _6136 = ((1.0f.xxx - clamp((f0 * _6112.x) + (f90.xxx * _6112.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _6136;\n    float _6142 = max(s.thickness, 0.0f);\n    bool _6147 = _6142 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _6147)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _6142);\n    }\n    bool _6172 = _612_fa_tr_a.w > 1.5f;\n    bool _6178;\n    if (_6172)\n    {\n        _6178 = _612_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _6178 = _6172;\n    }\n    bool _6185;\n    if (!_6178)\n    {\n        _6185 = _612_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _6185 = _6178;\n    }\n    if (_6185)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _6200 = float4(fa_world_pos, 1.0f);\n    float _6205 = dot(_612_fa_ct_vpw, _6200);\n    float2 uv0 = 0.5f.xx;\n    if (_6205 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _6223 = float2(dot(_612_fa_ct_vpx, _6200), dot(_612_fa_ct_vpy, _6200)) / _6205.xx;\n        float _6231;\n        if (_612_fa_ct_a.y > 0.5f)\n        {\n            _6231 = (_6223.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _6231 = 0.5f - (_6223.y * 0.5f);\n        }\n        uv0 = float2((_6223.x * 0.5f) + 0.5f, _6231);\n    }\n    if (_612_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _6252 = fa_xm_size(param_2);\n        float2 _6260 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _6252);\n        if (fa_screen_tex.Load(int3(int2(_6260), 0)).w > 0.5f)\n        {\n            int _6280 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6303 = abs(dx) > _6280;\n                    bool _6311;\n                    if (!_6303)\n                    {\n                        _6311 = abs(dy) > _6280;\n                    }\n                    else\n                    {\n                        _6311 = _6303;\n                    }\n                    if (_6311)\n                    {\n                        continue;\n                    }\n                    float4 _6332 = fa_screen_tex.Load(int3(int2(clamp(_6260 + float2(float(dx), float(dy)), 0.0f.xx, _6252 - 1.0f.xx)), 0));\n                    if (_6332.w > 0.5f)\n                    {\n                        acc += _6332.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _6136 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_6147)\n    {\n        float4 _6380 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _6142), 1.0f);\n        float _6385 = dot(_612_fa_ct_vpw, _6380);\n        uv = 0.5f.xx;\n        if (_6385 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6402 = float2(dot(_612_fa_ct_vpx, _6380), dot(_612_fa_ct_vpy, _6380)) / _6385.xx;\n            float _6410;\n            if (_612_fa_ct_a.y > 0.5f)\n            {\n                _6410 = (_6402.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6410 = 0.5f - (_6402.y * 0.5f);\n            }\n            uv = float2((_6402.x * 0.5f) + 0.5f, _6410);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_612_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2355_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3314 = int(_2355_fa_shadow_cfg.x + 0.5f);\n    float _3324 = dot(world - _2355_fa_shadow_eye.xyz, _2355_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3329 = _3314 > 0;\n    bool _3338;\n    if (_3329)\n    {\n        int param = _3314 - 1;\n        _3338 = _3324 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3338 = _3329;\n    }\n    if (_3338)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3344 = _3314 > 1;\n        bool _3351;\n        if (_3344)\n        {\n            _3351 = _3324 > _2355_fa_shadow_split.x;\n        }\n        else\n        {\n            _3351 = _3344;\n        }\n        if (_3351)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3357 = _3314 > 2;\n        bool _3364;\n        if (_3357)\n        {\n            _3364 = _3324 > _2355_fa_shadow_split.y;\n        }\n        else\n        {\n            _3364 = _3357;\n        }\n        if (_3364)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3370 = _3314 > 3;\n        bool _3377;\n        if (_3370)\n        {\n            _3377 = _3324 > _2355_fa_shadow_split.z;\n        }\n        else\n        {\n            _3377 = _3370;\n        }\n        if (_3377)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _9494 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9494 = -_9494;\n    }\n    float3 _8780 = normalize(_612_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9507 = { fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing };\n    SurfaceInput param_1 = _9507;\n    Surface _8788 = fa_standard_surface(param_1);\n    float3 _9525 = _8788.albedo;\n    float _9526 = _8788.alpha;\n    float3 _9527 = _8788.normal;\n    float _9528 = _8788.metallic;\n    float _9529 = _8788.roughness;\n    float _9530 = _8788.occlusion;\n    float3 _9531 = _8788.emission;\n    float _9532 = _8788.clearcoat;\n    float _9533 = _8788.clearcoat_roughness;\n    float3 _9534 = _8788.sheen_color;\n    float _9535 = _8788.sheen_roughness;\n    float _9536 = _8788.anisotropy;\n    float _9537 = _8788.anisotropy_rotation;\n    float _9538 = _8788.specular;\n    float _9539 = _8788.ior;\n    float3 _9540 = _8788.specular_color;\n    float _9541 = _8788.transmission;\n    float _9542 = _8788.thickness;\n    float3 _9543 = _8788.attenuation_color;\n    float _9544 = _8788.attenuation_distance;\n    SurfaceInput _9515 = { fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing };\n    SurfaceInput param_2 = _9515;\n    Surface param_3 = _8788;\n    surface(param_2, param_3);\n    _9525 = param_3.albedo;\n    _9526 = param_3.alpha;\n    _9527 = param_3.normal;\n    _9528 = param_3.metallic;\n    _9529 = param_3.roughness;\n    _9530 = param_3.occlusion;\n    _9531 = param_3.emission;\n    _9532 = param_3.clearcoat;\n    _9533 = param_3.clearcoat_roughness;\n    _9534 = param_3.sheen_color;\n    _9535 = param_3.sheen_roughness;\n    _9536 = param_3.anisotropy;\n    _9537 = param_3.anisotropy_rotation;\n    _9538 = param_3.specular;\n    _9539 = param_3.ior;\n    _9540 = param_3.specular_color;\n    _9541 = param_3.transmission;\n    _9542 = param_3.thickness;\n    _9543 = param_3.attenuation_color;\n    _9544 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9494;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9525 = param_6;\n    _9527 = param_7;\n    if (_9526 < _8816_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_612_fa_emissive.w > 0.5f)\n    {\n        result = _9525;\n    }\n    else\n    {\n        float3 _8840 = normalize(_9527);\n        float _8847 = clamp(_9528, 0.0f, 1.0f);\n        float _8851 = clamp(_9529, 0.0500000007450580596923828125f, 1.0f);\n        float _8855 = _8851 * _8851;\n        float _8859 = _8855 * _8855;\n        float _8864 = max(dot(_8840, _8780), 9.9999997473787516355514526367188e-05f);\n        float _8870 = 1.0f - _8847;\n        float _8871 = clamp(_9541, 0.0f, 1.0f) * _8870;\n        float3 _8880 = (_9525 * _8870) * (1.0f - _8871);\n        float3 _8887 = lerp(0.039999999105930328369140625f.xxx, _9525, _8847.xxx);\n        float3 f0 = _8887;\n        SurfaceInput _9523 = { fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing };\n        SurfaceInput param_8 = _9523;\n        Surface _9626 = { _9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544 };\n        Surface param_9 = _9626;\n        float3 param_10 = _8840;\n        float3 param_11 = _8780;\n        float param_12 = _8847;\n        float param_13 = _8851;\n        float3 param_14 = _8887;\n        FaLayers _8903 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8840;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8880) * _9530;\n        if (_8903.on)\n        {\n            lit *= _8903.base_scale;\n        }\n        int _8925 = fa_cl_ndir + fa_cl_local;\n        float _8990;\n        for (int ln = 0; ln < _8925; ln++)\n        {\n            int param_16 = ln;\n            int _8938 = fa_cl_light(param_16);\n            int param_17 = _8938;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8938;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9494;\n            LightSample _8954 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8962 = max(dot(_8840, _8954.direction), 0.0f);\n            float _8968 = _8954.attenuation * _8954.shadow;\n            float3 _8973 = normalize(_8954.direction + _8780);\n            float _8978 = max(dot(_8840, _8973), 0.0f);\n            float _8983 = max(dot(_8780, _8973), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8903.on)\n                {\n                    _8990 = _8903.f90;\n                }\n                else\n                {\n                    _8990 = 1.0f;\n                }\n                int param_21 = _8938;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8840;\n                float3 param_24 = _8780;\n                float3 param_25 = _8880;\n                float3 param_26 = f0;\n                float param_27 = _8990;\n                float param_28 = _8851;\n                float param_29 = _8864;\n                float param_30 = _8968;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8903.on)\n                {\n                    FaLayers param_31 = _8903;\n                    float3 param_32 = area;\n                    int param_33 = _8938;\n                    float3 param_34 = _8840;\n                    float3 param_35 = _8780;\n                    float3 param_36 = _8954.direction;\n                    float param_37 = _8864;\n                    float param_38 = _8968;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8903.on)\n                {\n                    FaLayers param_39 = _8903;\n                    float3 param_40 = _8880;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8840;\n                    float3 param_43 = _8780;\n                    float3 param_44 = _8954.direction;\n                    float3 param_45 = _8973;\n                    float param_46 = _8962;\n                    float param_47 = _8864;\n                    float param_48 = _8978;\n                    float param_49 = _8983;\n                    float param_50 = _8855;\n                    float param_51 = _8859;\n                    int param_52 = _8938;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8968));\n                }\n                else\n                {\n                    float _9092 = ((_8978 * _8978) * (_8859 - 1.0f)) + 1.0f;\n                    int param_53 = _8938;\n                    lit += (((_8880 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8983, 5.0f))) * (((_8859 / ((3.1415927410125732421875f * _9092) * _9092)) * (0.5f / max(lerp((2.0f * _8962) * _8864, _8962 + _8864, _8855), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8962))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8962 * _8968));\n                }\n            }\n        }\n        if (_8903.on)\n        {\n            FaLayers param_54 = _8903;\n            float3 param_55 = _8840;\n            float3 param_56 = _8780;\n            float3 param_57 = f0;\n            float param_58 = _8851;\n            float param_59 = _9530;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8840;\n            float3 param_61 = _8780;\n            float3 param_62 = f0;\n            float param_63 = _8851;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9530);\n        }\n        if (_8871 > 0.0f)\n        {\n            float _9190;\n            if (_8903.on)\n            {\n                _9190 = _8903.f90;\n            }\n            else\n            {\n                _9190 = 1.0f;\n            }\n            float _9198;\n            if (_8903.on)\n            {\n                _9198 = _8903.base_scale;\n            }\n            else\n            {\n                _9198 = 1.0f;\n            }\n            Surface _9647 = { _9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544 };\n            Surface param_64 = _9647;\n            float3 param_65 = _8840;\n            float3 param_66 = _8780;\n            float param_67 = _8851;\n            float3 param_68 = f0;\n            float param_69 = _9190;\n            float param_70 = _9198;\n            float param_71 = _8871;\n            float param_72 = fa_tr_blend;\n            float3 _9222 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9222;\n        }\n        result = lit;\n    }\n    float3 _9229 = result;\n    float3 _9230 = _9229 + _9531;\n    result = _9230;\n    float3 param_73 = _9230;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9239 = _612_fa_fog.w > 0.0f;\n    bool _9246;\n    if (!_9239)\n    {\n        _9246 = _612_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _9246 = _9239;\n    }\n    if (_9246)\n    {\n        float3 _9255 = fa_world_pos - _612_fa_camera_pos.xyz;\n        float _9261 = dot(_9255, _612_fa_fog_c.xyz);\n        bool _9265 = _612_fa_fog_c.w > 0.5f;\n        float _9266;\n        if (_9265)\n        {\n            _9266 = _9261;\n        }\n        else\n        {\n            _9266 = length(_9255);\n        }\n        float _9278 = _9266 - _612_fa_fog_b.x;\n        if (_9278 > 0.0f)\n        {\n            float _9287 = _612_fa_fog.w * _9278;\n            float tau = _9287 * _9287;\n            if (_612_fa_fog_b.y > 0.0f)\n            {\n                float _9303;\n                if (_9265)\n                {\n                    _9303 = fa_world_pos.y - (_612_fa_fog_c.y * _9261);\n                }\n                else\n                {\n                    _9303 = _612_fa_camera_pos.y;\n                }\n                float _9324 = lerp(_9303, fa_world_pos.y, clamp(_612_fa_fog_b.x / _9266, 0.0f, 1.0f));\n                float _9328 = fa_world_pos.y - _9324;\n                float _9333 = _9324 - _612_fa_fog_b.z;\n                float _9338 = fa_world_pos.y - _612_fa_fog_b.z;\n                bool _9341 = _9333 <= 0.0f;\n                bool _9342 = !_9341;\n                bool _9348;\n                if (_9342)\n                {\n                    _9348 = _612_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9348 = _9341;\n                }\n                float _9349;\n                if (_9348)\n                {\n                    _9349 = _612_fa_fog_b.y;\n                }\n                else\n                {\n                    _9349 = _612_fa_fog_b.y * exp(-min(_612_fa_fog_b.w * _9333, 80.0f));\n                }\n                bool _9376;\n                if (_9342)\n                {\n                    _9376 = _612_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9376 = _9341;\n                }\n                float _9377;\n                if (_9376)\n                {\n                    _9377 = _612_fa_fog_b.y * _9333;\n                }\n                else\n                {\n                    _9377 = (_612_fa_fog_b.y * (1.0f - exp(-min(_612_fa_fog_b.w * _9333, 80.0f)))) / _612_fa_fog_b.w;\n                }\n                bool _9402 = _9338 <= 0.0f;\n                bool _9409;\n                if (!_9402)\n                {\n                    _9409 = _612_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _9409 = _9402;\n                }\n                float _9410;\n                if (_9409)\n                {\n                    _9410 = _612_fa_fog_b.y * _9338;\n                }\n                else\n                {\n                    _9410 = (_612_fa_fog_b.y * (1.0f - exp(-min(_612_fa_fog_b.w * _9338, 80.0f)))) / _612_fa_fog_b.w;\n                }\n                float _9437;\n                if (abs(_9328) < 0.001000000047497451305389404296875f)\n                {\n                    _9437 = _9349;\n                }\n                else\n                {\n                    _9437 = (_9410 - _9377) / _9328;\n                }\n                tau += (_9278 * max(_9437, 0.0f));\n            }\n            result = lerp(result, _612_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9473 = 1.0f - fa_tr_blend;\n        result /= _9473.xxx;\n        _9526 *= _9473;\n    }\n    fa_frag_color = float4(result, _9526);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_612",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2355",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_8816",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _57_fa_view_proj : packoffset(c0);\n    row_major float4x4 _57_fa_light_vp : packoffset(c4);\n    float4 _57_fa_uv_scale : packoffset(c8);\n    float4 _57_fa_time : packoffset(c9);\n    float4 _57_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _225_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _225_fa_vel_prev_vp : packoffset(c4);\n    float4 _225_fa_vel_on : packoffset(c8);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_prev_r0 : TEXCOORD9;\n    float4 fa_prev_r1 : TEXCOORD10;\n    float4 fa_prev_r2 : TEXCOORD11;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4 fa_time_now()\n{\n    return _57_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _457 = { mul(float4(position, 1.0f), model).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * _57_fa_uv_scale.xy, color, position };\n    return _457;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = _225_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _464 = _246.world_pos;\n    float4 _257 = float4(_464, 1.0f);\n    fa_world_pos = _464;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -mul(_257, _57_fa_light_vp).z;\n    fa_pre_r0 = float3(_57_fa_light_vp[0].x, _57_fa_light_vp[1].x, _57_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_57_fa_light_vp[0].y, _57_fa_light_vp[1].y, _57_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_57_fa_light_vp[0].z, _57_fa_light_vp[1].z, _57_fa_light_vp[2].z);\n    gl_Position = mul(_257, _57_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_231)\n    {\n        float4 _330 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_257, _225_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_464 + mul(_330, fa_prev_model()).xyz) - mul(_330, model).xyz, 1.0f), _225_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n    float4 _129_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _616_alphaCutoff : packoffset(c0);\n    float _616_fa_pad0 : packoffset(c0.y);\n    float _616_fa_pad1 : packoffset(c0.z);\n    float _616_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _282 = fa_tex_fix(param_2, param_3);\n    float4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    float4 _298 = (_901 * _129_fa_base_color) * i.vertex_color;\n    float3 _856 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _334 = fa_tex_fix(param_6, param_7);\n        float3 _337 = (_334 * 2.0f) - 1.0f.xxx;\n        float2 _342 = _337.xy * _129_fa_maps.x;\n        float3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _373 = fa_tex_fix(param_12, param_13);\n    float4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    float4 _405 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = _129_fa_layers_a.x;\n    float _862 = _129_fa_layers_a.y;\n    float _865 = _129_fa_layers_a.z;\n    float _864 = _129_fa_layers_b.w;\n    float _867 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    Surface _894 = { _298.xyz, _298.w, _856, clamp(_129_fa_pbr.x * _373.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _373.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_417.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _449), _861, _862, _129_fa_layers_b.xyz, _864, _865, _129_fa_layers_a.w, _867, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _894;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    float3 _600 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _764 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param = _764;\n    Surface _605 = fa_standard_surface(param);\n    float3 _775 = _605.normal;\n    SurfaceInput _772 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param_1 = _772;\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < _616_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float3 _627 = normalize(_775);\n    float3 _642 = normalize(float3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    float2 e = _642.xy / ((abs(_642.x) + abs(_642.y)) + abs(_654)).xx;\n    if (_654 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_616",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _74_fa_view_proj : packoffset(c0);\n    row_major float4x4 _74_fa_light_vp : packoffset(c4);\n    float4 _74_fa_uv_scale : packoffset(c8);\n    float4 _74_fa_time : packoffset(c9);\n    float4 _74_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _213_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _470_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _470_fa_vel_prev_vp : packoffset(c4);\n    float4 _470_fa_vel_on : packoffset(c8);\n};\n\nTexture2D<float4> fa_prev_pal_tex : register(t0);\nSamplerState fa_prev_pal_smp : register(s11);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_prev_r0 : TEXCOORD11;\n    float4 fa_prev_r1 : TEXCOORD12;\n    float4 fa_prev_r2 : TEXCOORD13;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_213_fa_joint_rows[_204] * weights[i]);\n        r1 += (_213_fa_joint_rows[_204 + 1] * weights[i]);\n        r2 += (_213_fa_joint_rows[_204 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_time_now()\n{\n    return _74_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _718 = { mul(float4(position, 1.0f), model).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * _74_fa_uv_scale.xy, color, position };\n    return _718;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_prev_pal_texel(int t)\n{\n    return fa_prev_pal_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4x4 fa_prev_skin_matrix(float4 joints, float4 weights, int base)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0f) + 0.5f) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    float4 param_3 = fa_joints;\n    float4 param_4 = fa_weights;\n    int param_5 = int(_470_fa_vel_on.w + 0.5f);\n    return mul(fa_prev_skin_matrix(param_3, param_4, param_5), fa_rows_to_mat4(param, param_1, param_2));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = _470_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _725 = _490.world_pos;\n    float4 _501 = float4(_725, 1.0f);\n    fa_world_pos = _725;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -mul(_501, _74_fa_light_vp).z;\n    fa_pre_r0 = float3(_74_fa_light_vp[0].x, _74_fa_light_vp[1].x, _74_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_74_fa_light_vp[0].y, _74_fa_light_vp[1].y, _74_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_74_fa_light_vp[0].z, _74_fa_light_vp[1].z, _74_fa_light_vp[2].z);\n    gl_Position = mul(_501, _74_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_475)\n    {\n        float4 _574 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_501, _470_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_725 + mul(_574, fa_prev_model()).xyz) - mul(_574, model).xyz, 1.0f), _470_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    bool param_8 = _470_fa_vel_on.z > 0.5f;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n    float4 _129_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _616_alphaCutoff : packoffset(c0);\n    float _616_fa_pad0 : packoffset(c0.y);\n    float _616_fa_pad1 : packoffset(c0.z);\n    float _616_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _282 = fa_tex_fix(param_2, param_3);\n    float4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    float4 _298 = (_901 * _129_fa_base_color) * i.vertex_color;\n    float3 _856 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _334 = fa_tex_fix(param_6, param_7);\n        float3 _337 = (_334 * 2.0f) - 1.0f.xxx;\n        float2 _342 = _337.xy * _129_fa_maps.x;\n        float3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _373 = fa_tex_fix(param_12, param_13);\n    float4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    float4 _405 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _129_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = _129_fa_layers_a.x;\n    float _862 = _129_fa_layers_a.y;\n    float _865 = _129_fa_layers_a.z;\n    float _864 = _129_fa_layers_b.w;\n    float _867 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    Surface _894 = { _298.xyz, _298.w, _856, clamp(_129_fa_pbr.x * _373.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _373.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_417.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _449), _861, _862, _129_fa_layers_b.xyz, _864, _865, _129_fa_layers_a.w, _867, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _894;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    float3 _600 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _764 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param = _764;\n    Surface _605 = fa_standard_surface(param);\n    float3 _775 = _605.normal;\n    SurfaceInput _772 = { fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing };\n    SurfaceInput param_1 = _772;\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < _616_alphaCutoff)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float3 _627 = normalize(_775);\n    float3 _642 = normalize(float3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    float2 e = _642.xy / ((abs(_642.x) + abs(_642.y)) + abs(_654)).xx;\n    if (_654 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 13
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_213",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_470",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_616",
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
          },
          {
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 11
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11
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
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n    float4 _122_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _256 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _256;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_239, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n    float4 _226_fa_probe_sh[9] : packoffset(c32);\n    float4 _226_fa_atlas : packoffset(c41);\n    float4 _226_fa_rpa_tile : packoffset(c42);\n    float4 _226_fa_rpa_pos : packoffset(c43);\n    float4 _226_fa_rpa_bx : packoffset(c44);\n    float4 _226_fa_rpa_by : packoffset(c45);\n    float4 _226_fa_rpa_bz : packoffset(c46);\n    float4 _226_fa_rpb_tile : packoffset(c47);\n    float4 _226_fa_rpb_pos : packoffset(c48);\n    float4 _226_fa_rpb_bx : packoffset(c49);\n    float4 _226_fa_rpb_by : packoffset(c50);\n    float4 _226_fa_rpb_bz : packoffset(c51);\n    float4 _226_fa_gi : packoffset(c52);\n    float4 _226_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _577_alphaCutoff : packoffset(c0);\n    float _577_fa_pad0 : packoffset(c0.y);\n    float _577_fa_pad1 : packoffset(c0.z);\n    float _577_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    float4 _258 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _705 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _294 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_294 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _226_fa_maps.x;\n        float3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _333 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    float4 _365 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = _226_fa_layers_a.x;\n    float _711 = _226_fa_layers_a.y;\n    float _714 = _226_fa_layers_a.z;\n    float _713 = _226_fa_layers_b.w;\n    float _716 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    Surface _743 = { _258.xyz, _258.w, _705, clamp(_226_fa_pbr.x * _333.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _333.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_377.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _409), _710, _711, _226_fa_layers_b.xyz, _713, _714, _226_fa_layers_a.w, _716, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    float3 _561 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _613 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param = _613;\n    SurfaceInput _621 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param_1 = _621;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _577_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_577",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n    float4 _226_fa_ct_a : packoffset(c24);\n    float4 _226_fa_ct_b : packoffset(c25);\n    float4 _226_fa_ct_vpx : packoffset(c26);\n    float4 _226_fa_ct_vpy : packoffset(c27);\n    float4 _226_fa_ct_vpw : packoffset(c28);\n    float4 _226_fa_ct_fwd : packoffset(c29);\n    float4 _226_fa_tr_a : packoffset(c30);\n    float4 _226_fa_tr_b : packoffset(c31);\n    float4 _226_fa_probe_sh[9] : packoffset(c32);\n    float4 _226_fa_atlas : packoffset(c41);\n    float4 _226_fa_rpa_tile : packoffset(c42);\n    float4 _226_fa_rpa_pos : packoffset(c43);\n    float4 _226_fa_rpa_bx : packoffset(c44);\n    float4 _226_fa_rpa_by : packoffset(c45);\n    float4 _226_fa_rpa_bz : packoffset(c46);\n    float4 _226_fa_rpb_tile : packoffset(c47);\n    float4 _226_fa_rpb_pos : packoffset(c48);\n    float4 _226_fa_rpb_bx : packoffset(c49);\n    float4 _226_fa_rpb_by : packoffset(c50);\n    float4 _226_fa_rpb_bz : packoffset(c51);\n    float4 _226_fa_gi : packoffset(c52);\n    float4 _226_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _577_alphaCutoff : packoffset(c0);\n    float _577_fa_pad0 : packoffset(c0.y);\n    float _577_fa_pad1 : packoffset(c0.z);\n    float _577_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    float4 _258 = (_744 * _226_fa_base_color) * i.vertex_color;\n    float3 _705 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _294 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_294 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _226_fa_maps.x;\n        float3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _333 = fa_tex_fix(param_12, param_13);\n    float4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    float4 _365 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _226_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = _226_fa_layers_a.x;\n    float _711 = _226_fa_layers_a.y;\n    float _714 = _226_fa_layers_a.z;\n    float _713 = _226_fa_layers_b.w;\n    float _716 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    Surface _743 = { _258.xyz, _258.w, _705, clamp(_226_fa_pbr.x * _333.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _333.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_377.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _409), _710, _711, _226_fa_layers_b.xyz, _713, _714, _226_fa_layers_a.w, _716, _226_fa_layers_c.y, _226_fa_layers_d.xyz, _226_fa_tr_a.x, _226_fa_tr_a.y, _226_fa_tr_b.xyz, _226_fa_tr_a.z };\n    return _743;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    float3 _561 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _613 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param = _613;\n    SurfaceInput _621 = { fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing };\n    SurfaceInput param_1 = _621;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _577_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_577",
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
