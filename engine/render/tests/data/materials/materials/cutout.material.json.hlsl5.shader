{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "c074417cc32d65946d9fd800b8e1855ea5fc09e97e16038fe5558a6cb62d2704",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4320[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _637_fa_camera_pos : packoffset(c0);\n    float4 _637_fa_ambient : packoffset(c1);\n    float4 _637_fa_base_color : packoffset(c2);\n    float4 _637_fa_emissive : packoffset(c3);\n    float4 _637_fa_model_emissive : packoffset(c4);\n    float4 _637_fa_pbr : packoffset(c5);\n    float4 _637_fa_maps : packoffset(c6);\n    float4 _637_fa_fog : packoffset(c7);\n    float4 _637_fa_fog_b : packoffset(c8);\n    float4 _637_fa_fog_c : packoffset(c9);\n    float4 _637_fa_counts : packoffset(c10);\n    float4 _637_fa_env_sky : packoffset(c11);\n    float4 _637_fa_env_horizon : packoffset(c12);\n    float4 _637_fa_time : packoffset(c13);\n    float4 _637_fa_cl_vpx : packoffset(c14);\n    float4 _637_fa_cl_vpy : packoffset(c15);\n    float4 _637_fa_cl_vpw : packoffset(c16);\n    float4 _637_fa_cl_fwd : packoffset(c17);\n    float4 _637_fa_cl_grid : packoffset(c18);\n    float4 _637_fa_cl_info : packoffset(c19);\n    float4 _637_fa_layers_a : packoffset(c20);\n    float4 _637_fa_layers_b : packoffset(c21);\n    float4 _637_fa_layers_c : packoffset(c22);\n    float4 _637_fa_layers_d : packoffset(c23);\n    float4 _637_fa_ct_a : packoffset(c24);\n    float4 _637_fa_ct_b : packoffset(c25);\n    float4 _637_fa_ct_vpx : packoffset(c26);\n    float4 _637_fa_ct_vpy : packoffset(c27);\n    float4 _637_fa_ct_vpw : packoffset(c28);\n    float4 _637_fa_ct_fwd : packoffset(c29);\n    float4 _637_fa_tr_a : packoffset(c30);\n    float4 _637_fa_tr_b : packoffset(c31);\n    float4 _637_fa_probe_sh[9] : packoffset(c32);\n    float4 _637_fa_atlas : packoffset(c41);\n    float4 _637_fa_rpa_tile : packoffset(c42);\n    float4 _637_fa_rpa_pos : packoffset(c43);\n    float4 _637_fa_rpa_bx : packoffset(c44);\n    float4 _637_fa_rpa_by : packoffset(c45);\n    float4 _637_fa_rpa_bz : packoffset(c46);\n    float4 _637_fa_rpb_tile : packoffset(c47);\n    float4 _637_fa_rpb_pos : packoffset(c48);\n    float4 _637_fa_rpb_bx : packoffset(c49);\n    float4 _637_fa_rpb_by : packoffset(c50);\n    float4 _637_fa_rpb_bz : packoffset(c51);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2304_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2304_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2304_fa_shadow_info[4] : packoffset(c20);\n    float4 _2304_fa_shadow_split : packoffset(c24);\n    float4 _2304_fa_shadow_cfg : packoffset(c25);\n    float4 _2304_fa_shadow_bias : packoffset(c26);\n    float4 _2304_fa_shadow_eye : packoffset(c27);\n    float4 _2304_fa_shadow_fwd : packoffset(c28);\n    float4 _2304_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _7341_alphaCutoff : packoffset(c0);\n    float _7341_fa_pad0 : packoffset(c0.y);\n    float _7341_fa_pad1 : packoffset(c0.z);\n    float _7341_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1575 = _637_fa_cl_info.x < 0.0f;\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = _637_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    bool _1590;\n    if (!_1582)\n    {\n        _1590 = _637_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1590 = _1582;\n    }\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = _637_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = _637_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    if (_1604)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1614 = float4(world_pos, 1.0f);\n    float _1620 = dot(_637_fa_cl_vpw, _1614);\n    if (!(_1620 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1642 = float2(dot(_637_fa_cl_vpx, _1614), dot(_637_fa_cl_vpy, _1614)) / _1620.xx;\n    int _1646 = int(_637_fa_cl_grid.x);\n    int _1650 = int(_637_fa_cl_grid.y);\n    int param = (int(_637_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_637_fa_cl_fwd.xyz, world_pos) + _637_fa_cl_fwd.w, _637_fa_cl_grid.w) / _637_fa_cl_grid.w) * _637_fa_cl_grid.z)), 0, int(_637_fa_cl_info.y) - 1) * _1650) + clamp(int(floor(((_1642.y * 0.5f) + 0.5f) * _637_fa_cl_grid.y)), 0, _1650 - 1)) * _1646)) + clamp(int(floor(((_1642.x * 0.5f) + 0.5f) * _637_fa_cl_grid.x)), 0, _1646 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1726 = fa_cluster_texel(param);\n    return int2(int(_1726.x), int(_1726.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_637_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5781 = fa_cluster_lookup(param);\n    fa_cl_slot = _5781.x;\n    fa_cl_local = _5781.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6925 = fa_linear_to_srgb(param);\n        c = _6925;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6933 = fa_srgb_to_linear(param_1);\n            c = _6933;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _519;\n    if (i.front_facing)\n    {\n        _519 = i.world_normal;\n    }\n    else\n    {\n        _519 = -i.world_normal;\n    }\n    float3 _543 = normalize(i.world_tangent.xyz - (_519 * dot(_519, i.world_tangent.xyz)));\n    float3 _570 = normalize(((_543 * m.x) + ((cross(_519, _543) * i.world_tangent.w) * m.y)) + (_519 * m.z));\n    float3 _573;\n    if (i.front_facing)\n    {\n        _573 = _570;\n    }\n    else\n    {\n        _573 = -_570;\n    }\n    return _573;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _637_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6964 = fa_tex_fix(param_2, param_3);\n    float4 _8598 = base_t;\n    _8598.x = _6964.x;\n    _8598.y = _6964.y;\n    _8598.z = _6964.z;\n    base_t = _8598;\n    float4 _6978 = (_8598 * _637_fa_base_color) * i.vertex_color;\n    float3 _8382 = i.world_normal;\n    if (_637_fa_maps.z > 0.5f)\n    {\n        float param_4 = _637_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7010 = fa_tex_fix(param_6, param_7);\n        float3 _7013 = (_7010 * 2.0f) - 1.0f.xxx;\n        float2 _7018 = _7013.xy * _637_fa_maps.x;\n        float3 _8606 = _7013;\n        _8606.x = _7018.x;\n        _8606.y = _7018.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _8606;\n        _8382 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _637_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7046 = fa_tex_fix(param_12, param_13);\n    float4 _8609 = mrt;\n    _8609.x = _7046.x;\n    _8609.y = _7046.y;\n    _8609.z = _7046.z;\n    mrt = _8609;\n    float4 _7074 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _637_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7074.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7085 = fa_tex_fix(param_16, param_17);\n    float param_18 = _637_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7115 = fa_tex_fix(param_20, param_21);\n    float _8387 = _637_fa_layers_a.x;\n    float _8388 = _637_fa_layers_a.y;\n    float _8391 = _637_fa_layers_a.z;\n    float _8390 = _637_fa_layers_b.w;\n    float _8393 = _637_fa_layers_c.x;\n    if (_637_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_637_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _8387 *= _7085.y;\n            _8388 *= _7085.z;\n            _8390 *= _7074.w;\n        }\n        if (_637_fa_layers_c.z > 1.5f)\n        {\n            _8391 *= mrt.x;\n            _8393 *= mrt.w;\n        }\n    }\n    Surface _8420 = { _6978.xyz, _6978.w, _8382, clamp(_637_fa_pbr.x * _7046.z, 0.0f, 1.0f), clamp(_637_fa_pbr.y * _7046.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_637_fa_maps.y * (_7085.x - 1.0f)), _637_fa_emissive.xyz + (_637_fa_model_emissive.xyz * _7115), _8387, _8388, _637_fa_layers_b.xyz, _8390, _8391, _637_fa_layers_a.w, _8393, _637_fa_layers_c.y, _637_fa_layers_d.xyz, _637_fa_tr_a.x, _637_fa_tr_a.y, _637_fa_tr_b.xyz, _637_fa_tr_a.z };\n    return _8420;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1806 = rect.zw - rect.xy;\n    float2 _1810 = _1806 * atlas;\n    float2 _1814 = ddx * _1810;\n    float2 _1818 = ddy * _1810;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1806), clamp(0.5f * log2(max(max(dot(_1814, _1814), dot(_1818, _1818)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1851 = _637_fa_counts.y < 0.5f;\n    bool _1858;\n    if (!_1851)\n    {\n        _1858 = _637_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1858 = _1851;\n    }\n    if (_1858)\n    {\n        return;\n    }\n    float3 _1864 = ddx(world_pos);\n    float3 _1867 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1871 = fa_cluster_texel(param);\n    int _1875 = int(_1871.w);\n    if (_1875 < 1)\n    {\n        return;\n    }\n    int _1885 = int(_637_fa_counts.y + 0.5f);\n    int param_1 = _1885;\n    float4 _1889 = fa_light_texel(param_1);\n    float2 _1892 = _1889.yz;\n    int _1896 = int(_1889.w);\n    int param_2 = _1885 + 1;\n    float4 _1901 = fa_light_texel(param_2);\n    float _1902 = _1901.x;\n    int _1908 = int(_637_fa_counts.w + 0.5f) - 1;\n    int _1912 = int(_1871.z);\n    float3 _2177;\n    for (int k = 0; k < _1875; k++)\n    {\n        int _1925 = _1912 + k;\n        int param_3 = _1896 + (_1925 >> 2);\n        int _1942 = (_1885 + 2) + (int(fa_light_texel(param_3)[_1925 & 3]) * 7);\n        int param_4 = _1942 + 6;\n        float4 _1947 = fa_light_texel(param_4);\n        if (((int(_1947.w + 0.5f) >> _1908) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1942;\n        float4 _1962 = fa_light_texel(param_5);\n        int param_6 = _1942 + 1;\n        float4 _1967 = fa_light_texel(param_6);\n        int param_7 = _1942 + 2;\n        float4 _1972 = fa_light_texel(param_7);\n        float3 _1975 = _1962.xyz;\n        float _1980 = dot(_1975, world_pos) + _1962.w;\n        float3 _1982 = _1967.xyz;\n        float _1987 = dot(_1982, world_pos) + _1967.w;\n        float3 _1989 = _1972.xyz;\n        float _1994 = dot(_1989, world_pos) + _1972.w;\n        bool _1999 = abs(_1980) > 0.5f;\n        bool _2007;\n        if (!_1999)\n        {\n            _2007 = abs(_1987) > 0.5f;\n        }\n        else\n        {\n            _2007 = _1999;\n        }\n        bool _2015;\n        if (!_2007)\n        {\n            _2015 = abs(_1994) > 0.5f;\n        }\n        else\n        {\n            _2015 = _2007;\n        }\n        if (_2015)\n        {\n            continue;\n        }\n        float _2030 = clamp(dot(geo_normal, normalize(_1989)) * _1947.z, 0.0f, 1.0f);\n        if (_2030 <= 0.0f)\n        {\n            continue;\n        }\n        float _2050 = (clamp((0.5f - abs(_1994)) * 10.0f, 0.0f, 1.0f) * _2030) * _1947.x;\n        float2 _2058 = float2(_1980 + 0.5f, 0.5f - _1987);\n        float2 _2068 = float2(dot(_1975, _1864), dot(_1982, _1864));\n        float2 _2078 = float2(dot(_1975, _1867), dot(_1982, _1867));\n        int param_8 = _1942 + 5;\n        float4 _2083 = fa_light_texel(param_8);\n        int param_9 = _1942 + 3;\n        float4 _2088 = fa_light_texel(param_9);\n        int param_10 = _1942 + 4;\n        float4 _2093 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2083.xyz;\n        bool _2103 = _2088.z > _2088.x;\n        if (_2103)\n        {\n            float4 param_11 = _2088;\n            float2 param_12 = _2058;\n            float2 param_13 = _1892;\n            float2 param_14 = _2068;\n            float2 param_15 = _2078;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1902 > 0.5f) && (_1902 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2129 = fa_dc_to_linear(param_16);\n                float4 _8470 = tx;\n                _8470.x = _2129.x;\n                _8470.y = _2129.y;\n                _8470.z = _2129.z;\n                tx = _8470;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2050 * tex_a) * _2083.w, 0.0f, 1.0f).xxx);\n        if (_2093.z > _2093.x)\n        {\n            float4 param_17 = _2093;\n            float2 param_18 = _2058;\n            float2 param_19 = _1892;\n            float2 param_20 = _2068;\n            float2 param_21 = _2078;\n            float4 _2173 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1902 > 1.5f)\n            {\n                float3 param_22 = _2173.xyz;\n                float3 _2183 = fa_dc_to_srgb(param_22);\n                _2177 = _2183;\n            }\n            else\n            {\n                _2177 = _2173.xyz;\n            }\n            float3 _2192 = (_2177 * 2.0f) - 1.0f.xxx;\n            float2 _2197 = _2192.xy * _1947.y;\n            float3 _2219 = (normalize(_1975) * _2197.x) + (normalize(_1982) * _2197.y);\n            float3 _2222 = normalize(normal);\n            normal = normalize(lerp(_2222, normalize((_2222 * max(_2192.z, 0.0500000007450580596923828125f)) + (_2219 - (_2222 * dot(_2222, _2219)))), clamp(_2050 * (_2103 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4246 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4253 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4256 = int(_4246);\n    int _4259 = int(_4253);\n    float _4269 = _4253 - float(_4259);\n    int _4324 = (_4256 * 9) + _4259;\n    int _4344 = ((_4256 + 1) * 9) + _4259;\n    return lerp(lerp(_4320[_4324], _4320[_4324 + 1], _4269), lerp(_4320[_4344], _4320[_4344 + 1], _4269), _4246 - float(_4256));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _8305 = false;\n    float _8306 = 1.0f;\n    float _8307 = 1.0f;\n    float _8308 = 1.0f;\n    float _8309 = 0.0f;\n    float _8310 = 0.0f;\n    float _8311 = 0.0f;\n    float _8312 = 0.0f;\n    float _8314 = 1.0f;\n    bool _8315 = false;\n    float3 _8316 = 0.0f.xxx;\n    float _8317 = 1.0f;\n    float _8318 = 1.0f;\n    float _8319 = 1.0f;\n    float _8320 = 0.0f;\n    float _8321 = 0.0f;\n    float3 _8322 = float3(1.0f, 0.0f, 0.0f);\n    float3 _8323 = float3(0.0f, 0.0f, 1.0f);\n    float _8324 = 1.0f;\n    float _8325 = 1.0f;\n    float _4395 = clamp(s.specular, 0.0f, 1.0f);\n    float _4399 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4404 = (_4395 != 1.0f) || (_4399 != 1.5f);\n    bool _4413;\n    if (!_4404)\n    {\n        _4413 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4413 = _4404;\n    }\n    if (_4413)\n    {\n        float _4421 = (_4399 - 1.0f) / (_4399 + 1.0f);\n        f0 = lerp(min((_4421 * _4421).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4395, s.albedo, metallic.xxx);\n        _8306 = lerp(_4395, 1.0f, metallic);\n        _8305 = true;\n    }\n    float _4448 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4448 > 0.0f)\n    {\n        float _4456 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _8309 = _4448;\n        _8310 = _4456;\n        float _4463 = _4456 * _4456;\n        _8311 = _4463;\n        _8312 = _4463 * _4463;\n        float _4475 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _8314 = _4475;\n        _8307 = 1.0f - (_4448 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4475, 0.0f, 1.0f), 5.0f))));\n        _8305 = true;\n    }\n    float3 _4494 = max(s.sheen_color, 0.0f.xxx);\n    float _4503 = max(_4494.x, max(_4494.y, _4494.z));\n    if (_4503 > 0.0f)\n    {\n        float _4511 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _8315 = true;\n        _8316 = _4494;\n        _8317 = _4511;\n        _8318 = _4511 * _4511;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4511;\n        float _4528 = fa_sheen_albedo(param, param_1);\n        _8320 = _4528;\n        _8319 = 1.0f - min(_4503 * _4528, 1.0f);\n        _8305 = true;\n    }\n    _8308 = _8307 * _8319;\n    float _4547 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4547 != 0.0f)\n    {\n        float3 _4562 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4562;\n        if (dot(_4562, _4562) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4574 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4574.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4574.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4574.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4578 = t;\n        float3 _4579 = normalize(_4578);\n        t = _4579;\n        float3 _4604 = normalize((_4579 * cos(s.anisotropy_rotation)) + ((cross(n, _4579) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _8322 = _4604;\n        _8323 = cross(n, _4604);\n        float _4614 = roughness * roughness;\n        float _4620 = lerp(_4614, 1.0f, _4547 * _4547);\n        bool _4622 = _4547 > 0.0f;\n        _8324 = _4622 ? _4620 : _4614;\n        _8325 = _4622 ? _4614 : _4620;\n        _8321 = _4547;\n        _8305 = true;\n    }\n    FaLayers _8347 = { _8305, _8306, _8307, _8308, _8309, _8310, _8311, _8312, i.world_normal, _8314, _8315, _8316, _8317, _8318, _8319, _8320, _8321, _8322, _8323, _8324, _8325 };\n    return _8347;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3476_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3476_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_637_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3417 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3417;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4027 = (1.0f - _637_fa_rpa_tile.w) - _637_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4032 = _637_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4027 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4032)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _637_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4027;\n            }\n        }\n        else\n        {\n            amb = _637_fa_ambient.xyz * _4027;\n        }\n    }\n    bool _4083 = _637_fa_rpa_tile.w > 0.0f;\n    if (_4083)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _637_fa_rpa_tile.xy;\n            float param_4 = _637_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _637_fa_rpa_tile.w);\n        }\n    }\n    bool _4114 = _637_fa_rpb_tile.w > 0.0f;\n    if (_4114)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _637_fa_rpb_tile.xy;\n            float param_7 = _637_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _637_fa_rpb_tile.w);\n        }\n    }\n    if ((_4032 || _4083) || _4114)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_637_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _637_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_637_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_637_fa_cl_info.x) + int(_637_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_637_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5751;\n    if (fa_lm.z > 0.5f)\n    {\n        _5751 = 0.0f;\n    }\n    else\n    {\n        _5751 = 1.0f - clamp(_637_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5762 = _5751 < 1.0f;\n    bool _5768;\n    if (_5762)\n    {\n        int param = li;\n        _5768 = fa_light_baked(param);\n    }\n    else\n    {\n        _5768 = _5762;\n    }\n    return _5768 ? _5751 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _705_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _705_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _824 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _837 = (c - (ru * hx)) - p;\n        float3 _843 = ru * (2.0f * hx);\n        float _849 = max(dot(_843, _843), 9.9999999392252902907785028219223e-09f);\n        float _853 = dot(_837, _843);\n        float t = clamp((-_853) / _849, 0.0f, 1.0f);\n        if (_824)\n        {\n            float _868 = dot(r, _843);\n            float _874 = _849 - (_868 * _868);\n            if (abs(_874) > (9.9999997473787516355514526367188e-06f * _849))\n            {\n                t = clamp(((dot(r, _837) * _868) - _853) / _874, 0.0f, 1.0f);\n            }\n        }\n        return (p + _837) + (_843 * t);\n    }\n    float3 q = p;\n    float _906 = dot(r, axis);\n    bool _914;\n    if (_824)\n    {\n        _914 = abs(_906) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _914 = _824;\n    }\n    if (_914)\n    {\n        float _924 = dot(c - p, axis) / _906;\n        if (_924 > 0.0f)\n        {\n            q = p + (r * _924);\n        }\n    }\n    float3 _937 = q - c;\n    float2 xy = float2(dot(_937, ru), dot(_937, uu));\n    if (shape > 0.5f)\n    {\n        float _952 = length(xy);\n        if (_952 > hx)\n        {\n            xy *= (hx / _952);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _585 = abs(d);\n    float _587 = _585.x;\n    float _589 = _585.y;\n    bool _590 = _587 >= _589;\n    bool _598;\n    if (_590)\n    {\n        _598 = _587 >= _585.z;\n    }\n    else\n    {\n        _598 = _590;\n    }\n    int _599;\n    if (_598)\n    {\n        _599 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _614;\n        if (_589 >= _585.z)\n        {\n            _614 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _614 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _599 = _614;\n    }\n    return _599;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _744 = dot(d, right);\n    float _748 = dot(d, up);\n    float _759;\n    if (((_744 * _744) + (_748 * _748)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _759 = atan2(_748, _744) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _759 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_759 - floor(_759)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _990 = fa_light_base(param);\n    bool _994 = _637_fa_ambient.w > 4.5f;\n    int param_1 = _990;\n    float4 _998 = fa_light_texel(param_1);\n    int param_2 = _990 + 1;\n    float4 _1003 = fa_light_texel(param_2);\n    float _1006 = _1003.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1018 = _994 && (_1006 > 2.5f);\n    fa_light_is_area = _1018;\n    bool _1020 = _1006 < 0.5f;\n    float3 l;\n    if (_1020)\n    {\n        l = normalize(_998.xyz);\n        if (_994)\n        {\n            int param_3 = _990 + 6;\n            float4 _1034 = fa_light_texel(param_3);\n            if (_1034.z > 0.5f)\n            {\n                int param_4 = _990 + 4;\n                float4 _1044 = fa_light_texel(param_4);\n                int param_5 = _990 + 5;\n                float4 _1049 = fa_light_texel(param_5);\n                float2 param_6 = _1034.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1044.xyz) * _1044.w, (-dot(world_pos, _1049.xyz)) * _1049.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1079 = _998.xyz;\n        float3 _1081 = _1079 - world_pos;\n        float3 to_light = _1081;\n        float _1084 = length(_1081);\n        float reach = _1084;\n        bool front = true;\n        if (_1018)\n        {\n            int param_8 = _990 + 7;\n            reach = max(_1084 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _990 + 4;\n            float4 _1108 = fa_light_texel(param_9);\n            int param_10 = _990 + 5;\n            float4 _1113 = fa_light_texel(param_10);\n            int param_11 = _990 + 6;\n            float4 _1118 = fa_light_texel(param_11);\n            float _1119 = _1118.w;\n            int param_12 = _990 + 2;\n            float3 _1126 = normalize(fa_light_texel(param_12).xyz);\n            bool _1128 = _1119 > 1.5f;\n            bool _1136;\n            if (!_1128)\n            {\n                _1136 = dot(_1126, to_light) < 0.0f;\n            }\n            else\n            {\n                _1136 = _1128;\n            }\n            front = _1136;\n            float3 r = 0.0f.xxx;\n            float3 _1145 = _637_fa_camera_pos.xyz - world_pos;\n            bool _1149 = dot(n, n) > 0.5f;\n            bool _1157;\n            if (_1149)\n            {\n                _1157 = dot(_1145, _1145) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1157 = _1149;\n            }\n            if (_1157)\n            {\n                r = reflect(-normalize(_1145), normalize(n));\n            }\n            float3 param_13 = _1079;\n            float3 param_14 = _1126;\n            float3 param_15 = _1108.xyz;\n            float3 param_16 = _1113.xyz;\n            float param_17 = _1108.w;\n            float param_18 = _1113.w;\n            float param_19 = _1119;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1193 = length(to_light);\n        dist = _1193;\n        l = to_light / max(_1193, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1207 = reach / max(_998.w, 0.001000000047497451305389404296875f);\n        float _1213 = clamp(1.0f - (_1207 * _1207), 0.0f, 1.0f);\n        float _1215;\n        if (front)\n        {\n            _1215 = _1213 * _1213;\n        }\n        else\n        {\n            _1215 = 0.0f;\n        }\n        atten = _1215;\n        bool _1226 = _1006 < 2.5f;\n        if ((_1006 > 1.5f) && _1226)\n        {\n            int param_22 = _990 + 2;\n            float4 _1234 = fa_light_texel(param_22);\n            float _1244 = _1234.w;\n            int param_23 = _990 + 3;\n            float4 _1249 = fa_light_texel(param_23);\n            float _1250 = _1249.x;\n            float cos_inner = _1250;\n            if (_1250 > 1.5f)\n            {\n                cos_inner = lerp(_1244, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1244, cos_inner, dot(-l, normalize(_1234.xyz)));\n        }\n        if (_994 && (_1006 < 1.5f))\n        {\n            int param_24 = _990 + 6;\n            float4 _1274 = fa_light_texel(param_24);\n            if (_1274.z > 0.5f)\n            {\n                float3 _1282 = -to_light;\n                int param_25 = _990 + 4;\n                int param_26 = _990 + 5;\n                float3 _1296 = fa_light_texel(param_25).xyz;\n                float3 _1300 = fa_light_texel(param_26).xyz;\n                float3 _1309 = float3(dot(_1282, _1296), dot(_1282, _1300), dot(_1282, cross(_1296, _1300)));\n                float3 param_27 = _1309;\n                int _1313 = fa_cube_face(param_27);\n                int param_28 = _1313;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1340 = float2(dot(_1309, cross(param_29, param_30)), dot(_1309, param_30)) / max(dot(_1309, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1344 = _1313 / 3;\n                float2 param_31 = _1274.xy + (float2(float(_1313 - (_1344 * 3)), float(_1344)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1340.x), 0.5f - (0.5f * _1340.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _990 + 7;\n            float4 _1374 = fa_light_texel(param_33);\n            if (_1374.z > 0.5f)\n            {\n                int param_34 = _990 + 2;\n                int param_35 = _990 + 4;\n                int param_36 = _990 + 5;\n                float2 param_37 = _1374.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_994 && _1226)\n            {\n                int param_42 = _990 + 6;\n                float4 _1421 = fa_light_texel(param_42);\n                int param_43 = _990 + 7;\n                float4 _1426 = fa_light_texel(param_43);\n                bool _1429 = _1421.z > 0.5f;\n                bool _1436;\n                if (!_1429)\n                {\n                    _1436 = _1426.z > 0.5f;\n                }\n                else\n                {\n                    _1436 = _1429;\n                }\n                if (_1436)\n                {\n                    int param_44 = _990 + 2;\n                    float4 _1443 = fa_light_texel(param_44);\n                    float3 _1447 = normalize(_1443.xyz);\n                    int param_45 = _990 + 4;\n                    float4 _1452 = fa_light_texel(param_45);\n                    int param_46 = _990 + 5;\n                    float4 _1457 = fa_light_texel(param_46);\n                    if (_1429)\n                    {\n                        float3 _1465 = -to_light;\n                        float _1472 = _1443.w;\n                        float _1488 = 0.5f / max(dot(_1465, _1447) * (sqrt(max(1.0f - (_1472 * _1472), 0.0f)) / max(_1472, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1421.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1465, _1452.xyz) * _1488), 0.5f - (dot(_1465, _1457.xyz) * _1488));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1426.z > 0.5f)\n                    {\n                        float2 param_49 = _1426.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1447;\n                        float3 param_52 = _1452.xyz;\n                        float3 param_53 = _1457.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _8293 = _1003.xyz * atten;\n    if (_994)\n    {\n        _8293 *= fa_light_tint;\n    }\n    int _1557;\n    if (_1020)\n    {\n        _1557 = 0;\n    }\n    else\n    {\n        _1557 = ((_1006 > 1.5f) && (_1006 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _8304 = { l, _8293, atten, 1.0f, dist, _1557 };\n    return _8304;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2294;\n    if (i == 0)\n    {\n        _2294 = _2304_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2310;\n        if (i == 1)\n        {\n            _2310 = _2304_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2318;\n            if (i == 2)\n            {\n                _2318 = _2304_fa_shadow_split.z;\n            }\n            else\n            {\n                _2318 = _2304_fa_shadow_split.w;\n            }\n            _2310 = _2318;\n        }\n        _2294 = _2310;\n    }\n    return _2294;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2351 = fa_shadow_depth(param, param_1);\n    float _2355;\n    if (conv.x < 0.5f)\n    {\n        _2355 = _2351;\n    }\n    else\n    {\n        _2355 = (conv.y * conv.z) / (conv.z - (_2351 * (conv.z - conv.y)));\n    }\n    return _2355;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2282 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2282), sin(_2282)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2401 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2410;\n        if (k < 0.0f)\n        {\n            _2410 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2410 = k;\n        }\n        float _2430 = clamp((_2410 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2401;\n            float2 _2449 = fa_shadow_vogel(param_3, param_4, param_5) * _2430;\n            float2 param_6 = uv + (_2449 * _2304_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2461 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2461 < (zr - (length(_2449) * plane)))\n            {\n                sum += _2461;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2487 = sum / cnt;\n        float _2497;\n        if (k < 0.0f)\n        {\n            _2497 = (-k) / max(_2487, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2497 = k;\n        }\n        radius = clamp(((max(zr - _2487, 0.0f) * unit) * _2497) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2519 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2519; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2519;\n        float param_11 = _2401;\n        float2 _2538 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2538 * _2304_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2538) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2519);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2580 = max(_2304_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2585 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2591 = sqrt(1.0f - (_2585 * _2585));\n    float _2598 = min(_2591 / max(_2585, 0.20000000298023223876953125f), 4.0f);\n    float _2603;\n    if (_2304_fa_shadow_bias.y > 0.0f)\n    {\n        _2603 = _2304_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2603 = 1.5f * _2304_fa_shadow_info[ci].x;\n    }\n    float4 _2628 = mul(float4(world + (n * (_2603 * _2591)), 1.0f), _2304_fa_shadow_mat[ci]);\n    float _2635 = _2628.x;\n    bool _2638 = _2635 < _2304_fa_shadow_rect[ci].x;\n    bool _2647;\n    if (!_2638)\n    {\n        _2647 = _2635 > _2304_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2647 = _2638;\n    }\n    bool _2656;\n    if (!_2647)\n    {\n        _2656 = _2628.y < _2304_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2656 = _2647;\n    }\n    bool _2665;\n    if (!_2656)\n    {\n        _2665 = _2628.y > _2304_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2665 = _2656;\n    }\n    bool _2672;\n    if (!_2665)\n    {\n        _2672 = _2628.z > 1.0f;\n    }\n    else\n    {\n        _2672 = _2665;\n    }\n    if (_2672)\n    {\n        return -1.0f;\n    }\n    float _2680;\n    if (_2304_fa_shadow_bias.x > 0.0f)\n    {\n        _2680 = _2304_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2680 = 1.5f * _2304_fa_shadow_info[ci].x;\n    }\n    float2 param = _2628.xy;\n    float4 param_1 = _2304_fa_shadow_rect[ci];\n    float param_2 = _2628.z - ((_2680 * (1.0f + (0.5f * _2598))) / _2580);\n    float param_3 = _2304_fa_shadow_info[ci].x;\n    float param_4 = _2580;\n    float param_5 = _2580 * 0.25f;\n    float param_6 = ((_2304_fa_shadow_info[ci].x * min(_2598, 3.0f)) * 0.5f) / _2580;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2304_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2304_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_637_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3058 = int(_2304_fa_shadow_cfg.x + 0.5f);\n    if (_3058 < 1)\n    {\n        return 1.0f;\n    }\n    float _3073 = dot(world - _2304_fa_shadow_eye.xyz, _2304_fa_shadow_fwd.xyz);\n    int param = _3058 - 1;\n    if (_3073 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3085 = _3058 > 1;\n    bool _3092;\n    if (_3085)\n    {\n        _3092 = _3073 > _2304_fa_shadow_split.x;\n    }\n    else\n    {\n        _3092 = _3085;\n    }\n    if (_3092)\n    {\n        ci = 1;\n    }\n    bool _3096 = _3058 > 2;\n    bool _3103;\n    if (_3096)\n    {\n        _3103 = _3073 > _2304_fa_shadow_split.y;\n    }\n    else\n    {\n        _3103 = _3096;\n    }\n    if (_3103)\n    {\n        ci = 2;\n    }\n    bool _3107 = _3058 > 3;\n    bool _3114;\n    if (_3107)\n    {\n        _3114 = _3073 > _2304_fa_shadow_split.z;\n    }\n    else\n    {\n        _3114 = _3107;\n    }\n    if (_3114)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3058)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3140 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3140;\n        if (_3140 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2304_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3165;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3165 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3165 = _2304_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3184 = _2304_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3165, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3195 = clamp((_3073 - (fa_shadow_split_at(param_7) - _3184)) / _3184, 0.0f, 1.0f);\n        if (_3195 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3058)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3216 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3216;\n                if (_3216 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3195);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2738 = _637_fa_pbr.z < 0.5f;\n    bool _2745;\n    if (!_2738)\n    {\n        _2745 = _2304_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2745 = _2738;\n    }\n    if (_2745)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2304_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2758 = fa_light_texel(param);\n    float _2759 = _2758.x;\n    if (_2759 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2768 = int(_2759 + 0.5f);\n    int param_1 = _2768;\n    float4 _2772 = fa_light_texel(param_1);\n    int param_2 = _2768 + 1;\n    float4 _2777 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2780 = _2772.y;\n    if (_2780 > 0.0f)\n    {\n        float _2797 = 1.0f - smoothstep(0.75f * _2780, _2780, length(world - _2304_fa_shadow_eye.xyz));\n        fade = _2797;\n        if (_2797 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2772.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2821 = (_2768 + 2) + (face * 6);\n    int param_4 = _2821;\n    int param_5 = _2821 + 1;\n    int param_6 = _2821 + 3;\n    float4 _2835 = fa_light_texel(param_6);\n    int param_7 = _2821 + 4;\n    float4 _2840 = fa_light_texel(param_7);\n    int param_8 = _2821 + 5;\n    float4 _2845 = fa_light_texel(param_8);\n    float _2857 = _2845.x * max(dot(_2835, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2862 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2885 = clamp(dot(n, _2835.xyz), -1.0f, 1.0f);\n    float _2904 = min(sqrt(1.0f - (_2885 * _2885)) / max(abs(dot(n, world - lpos)) / max(dot(_2835, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2907 = _2777.y;\n    float _2909;\n    if (_2907 > 0.0f)\n    {\n        _2909 = _2907;\n    }\n    else\n    {\n        _2909 = 1.5f * _2857;\n    }\n    float4 _2929 = float4(world + (n * (_2909 * sqrt(1.0f - (_2862 * _2862)))), 1.0f);\n    float _2933 = dot(_2835, _2929);\n    float _2936 = _2845.y;\n    if (_2933 < _2936)\n    {\n        return 1.0f;\n    }\n    float2 _2951 = float2(dot(fa_light_texel(param_4), _2929), dot(fa_light_texel(param_5), _2929)) / _2933.xx;\n    float _2953 = _2951.x;\n    bool _2956 = _2953 < _2840.x;\n    bool _2965;\n    if (!_2956)\n    {\n        _2965 = _2953 > _2840.z;\n    }\n    else\n    {\n        _2965 = _2956;\n    }\n    bool _2974;\n    if (!_2965)\n    {\n        _2974 = _2951.y < _2840.y;\n    }\n    else\n    {\n        _2974 = _2965;\n    }\n    bool _2983;\n    if (!_2974)\n    {\n        _2983 = _2951.y > _2840.w;\n    }\n    else\n    {\n        _2983 = _2974;\n    }\n    if (_2983)\n    {\n        return 1.0f;\n    }\n    float _2989 = _2777.x;\n    float _2991;\n    if (_2989 > 0.0f)\n    {\n        _2991 = _2989;\n    }\n    else\n    {\n        _2991 = 1.5f * _2857;\n    }\n    float2 param_9 = _2951;\n    float4 param_10 = _2840;\n    float param_11 = _2933 - (_2991 * (1.0f + (0.5f * _2904)));\n    float param_12 = _2857;\n    float param_13 = 1.0f;\n    float param_14 = _2845.z * 0.25f;\n    float param_15 = (_2857 * min(_2904, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2936, _2845.z);\n    int param_17 = int(_2772.z + 0.5f);\n    float param_18 = _2772.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5132 = _637_fa_ct_a.x < 0.5f;\n    bool _5139;\n    if (!_5132)\n    {\n        _5139 = _2304_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5139 = _5132;\n    }\n    if (_5139)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2304_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5152 = fa_light_texel(param);\n    float _5153 = _5152.y;\n    float len = _5153;\n    if (_5153 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5165 = length(world - _637_fa_camera_pos.xyz);\n    float _5175 = 1.0f - smoothstep(0.5f * _637_fa_ct_b.x, _637_fa_ct_b.x, _5165);\n    if (_5175 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5181 = len;\n    float _5184 = min(_5181, 0.89999997615814208984375f * dist);\n    len = _5184;\n    float _5189 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5165);\n    float _5194 = _5189 + (0.5f * _5184);\n    float3 _5200 = world + (gn * _5189);\n    float _5202 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5266;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5217 = (float(k) + _5202) * 0.083333335816860198974609375f;\n        float3 _5225 = _5200 + (l * (_5217 * len));\n        float4 _5231 = float4(_5225, 1.0f);\n        float _5237 = dot(_637_fa_ct_vpw, _5231);\n        if (_5237 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5257 = float2(dot(_637_fa_ct_vpx, _5231), dot(_637_fa_ct_vpy, _5231)) / _5237.xx;\n        float _5261 = _5257.x * 0.5f;\n        float _5262 = _5261 + 0.5f;\n        if (_637_fa_ct_a.y > 0.5f)\n        {\n            _5266 = (_5257.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5266 = 0.5f - (_5257.y * 0.5f);\n        }\n        bool _5282 = _5262 < 0.0f;\n        bool _5289;\n        if (!_5282)\n        {\n            _5289 = _5262 >= 1.0f;\n        }\n        else\n        {\n            _5289 = _5282;\n        }\n        bool _5296;\n        if (!_5289)\n        {\n            _5296 = _5266 < 0.0f;\n        }\n        else\n        {\n            _5296 = _5289;\n        }\n        bool _5303;\n        if (!_5296)\n        {\n            _5303 = _5266 >= 1.0f;\n        }\n        else\n        {\n            _5303 = _5296;\n        }\n        if (_5303)\n        {\n            break;\n        }\n        float4 _5322 = fa_screen_tex.Load(int3(int2(float2(_5262, _5266) * _637_fa_ct_a.zw), 0));\n        if (_5322.w < 0.5f)\n        {\n            continue;\n        }\n        float _5341 = (dot(_637_fa_ct_fwd.xyz, _5225) + _637_fa_ct_fwd.w) - _5322.x;\n        if ((_5341 > _5189) && (_5341 < _5194))\n        {\n            occ = max(occ, (1.0f - (_5217 * _5217)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5262, 0.5f - _5261), min(_5266, 1.0f - _5266))));\n        }\n    }\n    return 1.0f - (occ * _5175);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5807 = fa_baked_keep(param);\n    if (_5807 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _8360 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _8360;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5833 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _8362 = _5833.color;\n    float _8363 = _5833.attenuation;\n    float _8364 = _5833.shadow;\n    bool _5836 = _5833.type == 0;\n    if (_5836 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5833.direction;\n        float _5847 = fa_shadow_factor(param_5, param_6);\n        _8364 = _5847;\n        _8362 *= _5847;\n    }\n    else\n    {\n        bool _5858 = _5833.type != 0;\n        bool _5864;\n        if (_5858)\n        {\n            _5864 = _8363 > 0.0f;\n        }\n        else\n        {\n            _5864 = _5858;\n        }\n        if (_5864)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5833.direction;\n            float _5883 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8364 = _5883;\n            _8362 *= _5883;\n        }\n    }\n    bool _5893 = _637_fa_ct_a.x > 0.5f;\n    bool _5899;\n    if (_5893)\n    {\n        _5899 = _8363 > 0.0f;\n    }\n    else\n    {\n        _5899 = _5893;\n    }\n    if (_5899)\n    {\n        float _5906;\n        if (_5836)\n        {\n            _5906 = 1000000000.0f;\n        }\n        else\n        {\n            _5906 = _5833._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5833.direction;\n        float param_18 = _5906;\n        float _5924 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8364 *= _5924;\n        _8362 *= _5924;\n    }\n    float _5937 = _8363;\n    float _5938 = _5937 * _5807;\n    _8363 = _5938;\n    float3 _5942 = _8362;\n    float3 _5943 = _5942 * _5807;\n    _8362 = _5943;\n    LightSample _8379 = { _5833.direction, _5943, _5938, _8364, _5833._distance, _5833.type };\n    return _8379;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5977 = v - (n * dot(v, n));\n    float3 t = _5977;\n    float _5981 = dot(_5977, _5977);\n    float l2 = _5981;\n    if (_5981 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5991;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5991 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5991 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5991;\n        l2 = dot(_5991, _5991);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6026 = dot(a, a);\n    float _6030 = dot(b, b);\n    if ((_6026 < 1.0000000195414813782625560981111e-24f) || (_6030 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6044 = a * rsqrt(_6026);\n    float3 _6049 = b * rsqrt(_6030);\n    float _6053 = dot(_6044, _6049);\n    float _6056 = abs(_6053);\n    float g = (((((((((((0.0416471660137176513671875f * _6056) - 0.1924748718738555908203125f) * _6056) + 0.4179156124591827392578125f) * _6056) - 0.616057217121124267578125f) * _6056) + 0.777722418308258056640625f) * _6056) - 0.999542415142059326171875f) * _6056) + 1.570791721343994140625f;\n    if (_6053 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6053 * _6053), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6044, _6049) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6113 = a.z > 0.0f;\n    bool _6117 = b.z > 0.0f;\n    if (_6113 && _6117)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6113 != _6117)\n        {\n            float3 _6152 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6152.z = 0.0f;\n            if (_6113)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6152;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6152;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6152;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6152;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6201 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6227 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6253 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6279 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6201;\n    float3 param_1 = _6227;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6227;\n    float3 param_7 = _6253;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6253;\n    float3 param_13 = _6279;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6279;\n    float3 param_19 = _6201;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6428 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6452 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6468 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6428;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6452;\n    float4 param_9 = m;\n    float3 param_10 = _6428;\n    float3 param_11 = _6452;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6468;\n    float4 param_14 = m;\n    float3 param_15 = _6428;\n    float3 param_16 = _6468;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6526 = fa_light_base(param);\n    int param_1 = _6526;\n    int param_2 = _6526 + 1;\n    int param_3 = _6526 + 2;\n    int param_4 = _6526 + 4;\n    float4 _6548 = fa_light_texel(param_4);\n    int param_5 = _6526 + 5;\n    float4 _6553 = fa_light_texel(param_5);\n    int param_6 = _6526 + 6;\n    float4 _6558 = fa_light_texel(param_6);\n    float _6559 = _6558.w;\n    float3 _6564 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6566 = _6559 < 1.5f;\n    bool _6573;\n    if (_6566)\n    {\n        _6573 = dot(normalize(fa_light_texel(param_3).xyz), _6564) >= 0.0f;\n    }\n    else\n    {\n        _6573 = _6566;\n    }\n    if (_6573)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6582 = (_6559 > 0.5f) && _6566;\n    float _6586 = _6582 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6589 = _6548.xyz;\n    float _6591 = _6548.w;\n    float3 _6597 = _6553.xyz;\n    float _6599 = _6553.w;\n    float3 up = _6597 * (_6599 * _6586);\n    float _6605;\n    if (_6582)\n    {\n        _6605 = (3.1415927410125732421875f * _6591) * _6591;\n    }\n    else\n    {\n        _6605 = (4.0f * _6591) * _6599;\n    }\n    if (_6559 > 1.5f)\n    {\n        float3 _6631 = cross(_6589, -_6564);\n        float3 perp = _6631;\n        float _6635 = dot(_6631, _6631);\n        float3 _6638;\n        if (_6635 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6638 = perp * rsqrt(_6635);\n        }\n        else\n        {\n            _6638 = _6597;\n        }\n        perp = _6638;\n        up = _6638 * _6599;\n    }\n    float _6659 = max(_6605, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6669 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6669;\n    float3 param_10 = n;\n    float3 param_11 = _6564;\n    float3 _6677 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6669;\n    float3 param_13 = n;\n    float3 param_14 = _6589 * (_6591 * _6586);\n    float3 _6685 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6669;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6693 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6559;\n    float3 param_20 = _6677;\n    float3 param_21 = _6685;\n    float3 param_22 = _6693;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6712 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6712;\n    float2 param_26 = _6712 + float2(64.0f, 0.0f);\n    float4 _6722 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6559;\n    float3 param_29 = _6677;\n    float3 param_30 = _6685;\n    float3 param_31 = _6693;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6722.x) + ((f90.xxx - f0) * _6722.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6564, _6564)) + _6659) / _6659) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4869 = 1.0f / alpha;\n    return ((2.0f + _4869) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4869)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4904 = max(dot(L.nc, l), 0.0f);\n    float _4910 = max(dot(L.nc, h), 0.0f);\n    float _4919 = ((_4910 * _4910) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4919) * _4919)) * (0.5f / max(lerp((2.0f * _4904) * L.coat_ndv, _4904 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4904)) * _4904;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6790;\n    if (L.sheen_on)\n    {\n        _6790 = L.sheen_scale;\n    }\n    else\n    {\n        _6790 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6790);\n    float3 _6803 = normalize(l + v);\n    int param_10 = li;\n    float3 _6814 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6823 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6803), 0.0f);\n        float param_13 = _6823;\n        float param_14 = ndv;\n        result += ((L.sheen * _6814) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6823)) * _6823) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6803;\n        float param_18 = max(dot(v, _6803), 0.0f);\n        result += (_6814 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4772 = tdh / at;\n    float _4776 = bdh / ab;\n    float _4788 = ((_4772 * _4772) + (_4776 * _4776)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4788) * _4788);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4968 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5047 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5047) * _5047);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4968);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4968));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4178 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4181 = _4178.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4181 * _4181, exp2((-9.27999973297119140625f) * ndv)) * _4181) + _4178.y)) + _4178.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3437 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3440 = _3437.x;\n    float _3442 = _3437.z;\n    float2 e = float2(_3440, _3442);\n    if (_3437.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3442)) * ((_3440 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3440)) * ((_3442 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3489;\n    if (lv == 0)\n    {\n        _3489 = 0.0f;\n    }\n    else\n    {\n        _3489 = res + 2.0f;\n    }\n    float _3499;\n    if (lv == 0)\n    {\n        _3499 = 0.0f;\n    }\n    else\n    {\n        _3499 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3489, _3499)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3544;\n    if (res > 64.5f)\n    {\n        _3544 = 5.0f;\n    }\n    else\n    {\n        _3544 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3559 = clamp(rough, 0.0f, 1.0f) * (_3544 - 1.0f);\n    int _3566 = int(min(floor(_3559), _3544 - 2.0f));\n    float _3571 = _3559 - float(_3566);\n    float3 param = d;\n    float2 _3575 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3566;\n    float2 param_4 = _3575;\n    float3 _3585 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3571 < 0.00200000009499490261077880859375f)\n    {\n        return _3585;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3566 + 1;\n    float2 param_8 = _3575;\n    return lerp(_3585, fa_probe_level(param_5, param_6, param_7, param_8), _3571.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3655 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3662 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3669 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3675 = dot(bx.xyz, d);\n    float _3679 = dot(by.xyz, d);\n    float _3683 = dot(bz.xyz, d);\n    float _3689;\n    if (_3675 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3689 = (1.0f - _3655) / _3675;\n    }\n    else\n    {\n        float _3703;\n        if (_3675 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3703 = ((-1.0f) - _3655) / _3675;\n        }\n        else\n        {\n            _3703 = 1000000015047466219876688855040.0f;\n        }\n        _3689 = _3703;\n    }\n    float tx = _3689;\n    float _3720;\n    if (_3679 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3720 = (1.0f - _3662) / _3679;\n    }\n    else\n    {\n        float _3733;\n        if (_3679 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3733 = ((-1.0f) - _3662) / _3679;\n        }\n        else\n        {\n            _3733 = 1000000015047466219876688855040.0f;\n        }\n        _3720 = _3733;\n    }\n    float ty = _3720;\n    float _3749;\n    if (_3683 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3749 = (1.0f - _3669) / _3683;\n    }\n    else\n    {\n        float _3762;\n        if (_3683 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3762 = ((-1.0f) - _3669) / _3683;\n        }\n        else\n        {\n            _3762 = 1000000015047466219876688855040.0f;\n        }\n        _3749 = _3762;\n    }\n    float _3774 = tx;\n    float _3777 = (_3774 > 0.0f) ? _3774 : 1000000015047466219876688855040.0f;\n    tx = _3777;\n    float _3778 = ty;\n    float _3781 = (_3778 > 0.0f) ? _3778 : 1000000015047466219876688855040.0f;\n    ty = _3781;\n    float _3791 = min(_3777, min(_3781, (_3749 > 0.0f) ? _3749 : 1000000015047466219876688855040.0f));\n    if (_3791 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3807 = (fa_world_pos + (d * _3791)) - posw.xyz;\n    float3 _3812;\n    if (dot(_3807, _3807) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3812 = normalize(_3807);\n    }\n    else\n    {\n        _3812 = d;\n    }\n    return _3812;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3858 = (1.0f - _637_fa_rpa_tile.w) - _637_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3858 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_637_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _637_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3887 = rough * rough;\n            float _3918 = 0.60000002384185791015625f * _3887;\n            base = lerp(lerp(_637_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_637_fa_env_horizon.xyz, _637_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3887)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3918, 0.0500000007450580596923828125f + _3918, d.y).xxx), ((_637_fa_env_sky.xyz + _637_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3887 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3858;\n    }\n    if (_637_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _637_fa_rpa_tile;\n        float4 param_5 = _637_fa_rpa_pos;\n        float4 param_6 = _637_fa_rpa_bx;\n        float4 param_7 = _637_fa_rpa_by;\n        float4 param_8 = _637_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3977 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3977 * _637_fa_rpa_tile.w);\n    }\n    if (_637_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _637_fa_rpb_tile;\n        float4 param_12 = _637_fa_rpb_pos;\n        float4 param_13 = _637_fa_rpb_bx;\n        float4 param_14 = _637_fa_rpb_by;\n        float4 param_15 = _637_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4009 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4009 * _637_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4655;\n        if (L.aniso >= 0.0f)\n        {\n            _4655 = L.b;\n        }\n        else\n        {\n            _4655 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4655, v), _4655), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4688 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4688.x) + (L.f90.xxx * _4688.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4743 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4743.x) + _4743.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4220 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4220.x) + _4220.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_637_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_637_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5445 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5449 = fa_xm_origin(param_1);\n    float2 _5455 = (uv * _5445) - 0.5f.xx;\n    float2 _5458 = frac(_5455);\n    float2 _5461 = floor(_5455);\n    float2 param_2 = _5445;\n    float2 param_3 = _5449;\n    float2 param_4 = _5461;\n    float2 param_5 = _5445;\n    float2 param_6 = _5449;\n    float2 param_7 = _5461 + float2(1.0f, 0.0f);\n    float2 param_8 = _5445;\n    float2 param_9 = _5449;\n    float2 param_10 = _5461 + float2(0.0f, 1.0f);\n    float2 param_11 = _5445;\n    float2 param_12 = _5449;\n    float2 param_13 = _5461 + 1.0f.xx;\n    float3 _5503 = _5458.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5503), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5503), _5458.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5522 = max(_637_fa_tr_b.w - 1.0f, 0.0f);\n    float _5526 = clamp(lod, 0.0f, _5522);\n    int _5530 = int(floor(_5526));\n    int param = _5530;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5540 = float(_5530);\n    float _5541 = _5526 - _5540;\n    bool _5543 = _5541 > 0.001000000047497451305389404296875f;\n    bool _5550;\n    if (_5543)\n    {\n        _5550 = _5540 < _5522;\n    }\n    else\n    {\n        _5550 = _5543;\n    }\n    if (_5550)\n    {\n        int param_2 = _5530 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5541.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5576 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _5576.x) + (f90.xxx * _5576.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _5604 = max(s.thickness, 0.0f);\n    bool _5609 = _5604 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5609)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5604);\n    }\n    bool _5634 = _637_fa_tr_a.w > 1.5f;\n    bool _5641;\n    if (!_5634)\n    {\n        _5641 = _637_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5641 = _5634;\n    }\n    if (_5641)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_5609)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5604);\n    }\n    float4 _5676 = float4(world, 1.0f);\n    float _5681 = dot(_637_fa_ct_vpw, _5676);\n    float2 uv = 0.5f.xx;\n    if (_5681 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5699 = float2(dot(_637_fa_ct_vpx, _5676), dot(_637_fa_ct_vpy, _5676)) / _5681.xx;\n        float _5707;\n        if (_637_fa_ct_a.y > 0.5f)\n        {\n            _5707 = (_5699.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5707 = 0.5f - (_5699.y * 0.5f);\n        }\n        uv = float2((_5699.x * 0.5f) + 0.5f, _5707);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_637_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2304_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3240 = int(_2304_fa_shadow_cfg.x + 0.5f);\n    float _3250 = dot(world - _2304_fa_shadow_eye.xyz, _2304_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3255 = _3240 > 0;\n    bool _3264;\n    if (_3255)\n    {\n        int param = _3240 - 1;\n        _3264 = _3250 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3264 = _3255;\n    }\n    if (_3264)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3270 = _3240 > 1;\n        bool _3277;\n        if (_3270)\n        {\n            _3277 = _3250 > _2304_fa_shadow_split.x;\n        }\n        else\n        {\n            _3277 = _3270;\n        }\n        if (_3277)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3283 = _3240 > 2;\n        bool _3290;\n        if (_3283)\n        {\n            _3290 = _3250 > _2304_fa_shadow_split.y;\n        }\n        else\n        {\n            _3290 = _3283;\n        }\n        if (_3290)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3296 = _3240 > 3;\n        bool _3303;\n        if (_3296)\n        {\n            _3303 = _3250 > _2304_fa_shadow_split.z;\n        }\n        else\n        {\n            _3303 = _3296;\n        }\n        if (_3303)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _8021 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8021 = -_8021;\n    }\n    float3 _7305 = normalize(_637_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _8034 = { fa_world_pos, _8021, fa_world_tangent, fa_uv, fa_vertex_color, _7305, gl_FrontFacing };\n    SurfaceInput param_1 = _8034;\n    Surface _7313 = fa_standard_surface(param_1);\n    float3 _8052 = _7313.albedo;\n    float _8053 = _7313.alpha;\n    float3 _8054 = _7313.normal;\n    float _8055 = _7313.metallic;\n    float _8056 = _7313.roughness;\n    float _8057 = _7313.occlusion;\n    float3 _8058 = _7313.emission;\n    float _8059 = _7313.clearcoat;\n    float _8060 = _7313.clearcoat_roughness;\n    float3 _8061 = _7313.sheen_color;\n    float _8062 = _7313.sheen_roughness;\n    float _8063 = _7313.anisotropy;\n    float _8064 = _7313.anisotropy_rotation;\n    float _8065 = _7313.specular;\n    float _8066 = _7313.ior;\n    float3 _8067 = _7313.specular_color;\n    float _8068 = _7313.transmission;\n    float _8069 = _7313.thickness;\n    float3 _8070 = _7313.attenuation_color;\n    float _8071 = _7313.attenuation_distance;\n    SurfaceInput _8042 = { fa_world_pos, _8021, fa_world_tangent, fa_uv, fa_vertex_color, _7305, gl_FrontFacing };\n    SurfaceInput param_2 = _8042;\n    Surface param_3 = _7313;\n    surface(param_2, param_3);\n    _8052 = param_3.albedo;\n    _8053 = param_3.alpha;\n    _8054 = param_3.normal;\n    _8055 = param_3.metallic;\n    _8056 = param_3.roughness;\n    _8057 = param_3.occlusion;\n    _8058 = param_3.emission;\n    _8059 = param_3.clearcoat;\n    _8060 = param_3.clearcoat_roughness;\n    _8061 = param_3.sheen_color;\n    _8062 = param_3.sheen_roughness;\n    _8063 = param_3.anisotropy;\n    _8064 = param_3.anisotropy_rotation;\n    _8065 = param_3.specular;\n    _8066 = param_3.ior;\n    _8067 = param_3.specular_color;\n    _8068 = param_3.transmission;\n    _8069 = param_3.thickness;\n    _8070 = param_3.attenuation_color;\n    _8071 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _8021;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8052 = param_6;\n    _8054 = param_7;\n    if (_8053 < _7341_alphaCutoff)\n    {\n        discard;\n    }\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_637_fa_emissive.w > 0.5f)\n    {\n        result = _8052;\n    }\n    else\n    {\n        float3 _7364 = normalize(_8054);\n        float _7371 = clamp(_8055, 0.0f, 1.0f);\n        float _7375 = clamp(_8056, 0.0500000007450580596923828125f, 1.0f);\n        float _7379 = _7375 * _7375;\n        float _7383 = _7379 * _7379;\n        float _7388 = max(dot(_7364, _7305), 9.9999997473787516355514526367188e-05f);\n        float _7394 = 1.0f - _7371;\n        float _7395 = clamp(_8068, 0.0f, 1.0f) * _7394;\n        float3 _7404 = (_8052 * _7394) * (1.0f - _7395);\n        float3 _7411 = lerp(0.039999999105930328369140625f.xxx, _8052, _7371.xxx);\n        float3 f0 = _7411;\n        SurfaceInput _8050 = { fa_world_pos, _8021, fa_world_tangent, fa_uv, fa_vertex_color, _7305, gl_FrontFacing };\n        SurfaceInput param_8 = _8050;\n        Surface _8153 = { _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066, _8067, _8068, _8069, _8070, _8071 };\n        Surface param_9 = _8153;\n        float3 param_10 = _7364;\n        float3 param_11 = _7305;\n        float param_12 = _7371;\n        float param_13 = _7375;\n        float3 param_14 = _7411;\n        FaLayers _7427 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _7364;\n        float3 lit = (fa_indirect_diffuse(param_15) * _7404) * _8057;\n        if (_7427.on)\n        {\n            lit *= _7427.base_scale;\n        }\n        int _7449 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7449; ln++)\n        {\n            int param_16 = ln;\n            int _7462 = fa_cl_light(param_16);\n            int param_17 = _7462;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _7462;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _8021;\n            LightSample _7478 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7486 = max(dot(_7364, _7478.direction), 0.0f);\n            float _7492 = _7478.attenuation * _7478.shadow;\n            float3 _7497 = normalize(_7478.direction + _7305);\n            float _7502 = max(dot(_7364, _7497), 0.0f);\n            float _7507 = max(dot(_7305, _7497), 0.0f);\n            bool _7514;\n            if (fa_light_is_area)\n            {\n                _7514 = !_7427.on;\n            }\n            else\n            {\n                _7514 = fa_light_is_area;\n            }\n            if (_7514)\n            {\n                int param_21 = _7462;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _7364;\n                float3 param_24 = _7305;\n                float3 param_25 = _7404;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _7375;\n                float param_29 = _7388;\n                float param_30 = _7492;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7427;\n                    int param_32 = _7462;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _7364;\n                    float3 param_35 = _7305;\n                    float3 param_36 = _7478.direction;\n                    float3 param_37 = _7404;\n                    float3 param_38 = f0;\n                    float param_39 = _7375;\n                    float param_40 = _7388;\n                    float param_41 = _7492;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7427.on)\n                    {\n                        FaLayers param_42 = _7427;\n                        float3 param_43 = _7404;\n                        float3 param_44 = f0;\n                        float3 param_45 = _7364;\n                        float3 param_46 = _7305;\n                        float3 param_47 = _7478.direction;\n                        float3 param_48 = _7497;\n                        float param_49 = _7486;\n                        float param_50 = _7388;\n                        float param_51 = _7502;\n                        float param_52 = _7507;\n                        float param_53 = _7379;\n                        float param_54 = _7383;\n                        int param_55 = _7462;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7492));\n                    }\n                    else\n                    {\n                        float _7620 = ((_7502 * _7502) * (_7383 - 1.0f)) + 1.0f;\n                        int param_56 = _7462;\n                        lit += (((_7404 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _7507, 5.0f))) * (((_7383 / ((3.1415927410125732421875f * _7620) * _7620)) * (0.5f / max(lerp((2.0f * _7486) * _7388, _7486 + _7388, _7379), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _7486))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7486 * _7492));\n                    }\n                }\n            }\n        }\n        if (_7427.on)\n        {\n            FaLayers param_57 = _7427;\n            float3 param_58 = _7364;\n            float3 param_59 = _7305;\n            float3 param_60 = f0;\n            float param_61 = _7375;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8057);\n        }\n        else\n        {\n            float3 param_62 = _7364;\n            float3 param_63 = _7305;\n            float3 param_64 = f0;\n            float param_65 = _7375;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8057);\n        }\n        if (_7395 > 0.0f)\n        {\n            float _7718;\n            if (_7427.on)\n            {\n                _7718 = _7427.f90;\n            }\n            else\n            {\n                _7718 = 1.0f;\n            }\n            float _7726;\n            if (_7427.on)\n            {\n                _7726 = _7427.base_scale;\n            }\n            else\n            {\n                _7726 = 1.0f;\n            }\n            Surface _8174 = { _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066, _8067, _8068, _8069, _8070, _8071 };\n            Surface param_66 = _8174;\n            float3 param_67 = _7364;\n            float3 param_68 = _7305;\n            float param_69 = _7375;\n            float3 param_70 = f0;\n            float param_71 = _7718;\n            float param_72 = _7726;\n            float param_73 = _7395;\n            float param_74 = fa_tr_blend;\n            float3 _7750 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7750;\n        }\n        result = lit;\n    }\n    float3 _7757 = result;\n    float3 _7758 = _7757 + _8058;\n    result = _7758;\n    float3 param_75 = _7758;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7767 = _637_fa_fog.w > 0.0f;\n    bool _7774;\n    if (!_7767)\n    {\n        _7774 = _637_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7774 = _7767;\n    }\n    if (_7774)\n    {\n        float3 _7783 = fa_world_pos - _637_fa_camera_pos.xyz;\n        float _7789 = dot(_7783, _637_fa_fog_c.xyz);\n        bool _7793 = _637_fa_fog_c.w > 0.5f;\n        float _7794;\n        if (_7793)\n        {\n            _7794 = _7789;\n        }\n        else\n        {\n            _7794 = length(_7783);\n        }\n        float _7806 = _7794 - _637_fa_fog_b.x;\n        if (_7806 > 0.0f)\n        {\n            float _7815 = _637_fa_fog.w * _7806;\n            float tau = _7815 * _7815;\n            if (_637_fa_fog_b.y > 0.0f)\n            {\n                float _7831;\n                if (_7793)\n                {\n                    _7831 = fa_world_pos.y - (_637_fa_fog_c.y * _7789);\n                }\n                else\n                {\n                    _7831 = _637_fa_camera_pos.y;\n                }\n                float _7852 = lerp(_7831, fa_world_pos.y, clamp(_637_fa_fog_b.x / _7794, 0.0f, 1.0f));\n                float _7856 = fa_world_pos.y - _7852;\n                float _7861 = _7852 - _637_fa_fog_b.z;\n                float _7866 = fa_world_pos.y - _637_fa_fog_b.z;\n                bool _7869 = _7861 <= 0.0f;\n                bool _7870 = !_7869;\n                bool _7876;\n                if (_7870)\n                {\n                    _7876 = _637_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7876 = _7869;\n                }\n                float _7877;\n                if (_7876)\n                {\n                    _7877 = _637_fa_fog_b.y;\n                }\n                else\n                {\n                    _7877 = _637_fa_fog_b.y * exp(-min(_637_fa_fog_b.w * _7861, 80.0f));\n                }\n                bool _7904;\n                if (_7870)\n                {\n                    _7904 = _637_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7904 = _7869;\n                }\n                float _7905;\n                if (_7904)\n                {\n                    _7905 = _637_fa_fog_b.y * _7861;\n                }\n                else\n                {\n                    _7905 = (_637_fa_fog_b.y * (1.0f - exp(-min(_637_fa_fog_b.w * _7861, 80.0f)))) / _637_fa_fog_b.w;\n                }\n                bool _7930 = _7866 <= 0.0f;\n                bool _7937;\n                if (!_7930)\n                {\n                    _7937 = _637_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7937 = _7930;\n                }\n                float _7938;\n                if (_7937)\n                {\n                    _7938 = _637_fa_fog_b.y * _7866;\n                }\n                else\n                {\n                    _7938 = (_637_fa_fog_b.y * (1.0f - exp(-min(_637_fa_fog_b.w * _7866, 80.0f)))) / _637_fa_fog_b.w;\n                }\n                float _7965;\n                if (abs(_7856) < 0.001000000047497451305389404296875f)\n                {\n                    _7965 = _7877;\n                }\n                else\n                {\n                    _7965 = (_7938 - _7905) / _7856;\n                }\n                tau += (_7806 * max(_7965, 0.0f));\n            }\n            result = lerp(result, _637_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _8001 = 1.0f - fa_tr_blend;\n        result /= _8001.xxx;\n        _8053 *= _8001;\n    }\n    fa_frag_color = float4(result, _8053);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_637",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2304",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_7341",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4320[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _637_fa_camera_pos : packoffset(c0);\n    float4 _637_fa_ambient : packoffset(c1);\n    float4 _637_fa_base_color : packoffset(c2);\n    float4 _637_fa_emissive : packoffset(c3);\n    float4 _637_fa_model_emissive : packoffset(c4);\n    float4 _637_fa_pbr : packoffset(c5);\n    float4 _637_fa_maps : packoffset(c6);\n    float4 _637_fa_fog : packoffset(c7);\n    float4 _637_fa_fog_b : packoffset(c8);\n    float4 _637_fa_fog_c : packoffset(c9);\n    float4 _637_fa_counts : packoffset(c10);\n    float4 _637_fa_env_sky : packoffset(c11);\n    float4 _637_fa_env_horizon : packoffset(c12);\n    float4 _637_fa_time : packoffset(c13);\n    float4 _637_fa_cl_vpx : packoffset(c14);\n    float4 _637_fa_cl_vpy : packoffset(c15);\n    float4 _637_fa_cl_vpw : packoffset(c16);\n    float4 _637_fa_cl_fwd : packoffset(c17);\n    float4 _637_fa_cl_grid : packoffset(c18);\n    float4 _637_fa_cl_info : packoffset(c19);\n    float4 _637_fa_layers_a : packoffset(c20);\n    float4 _637_fa_layers_b : packoffset(c21);\n    float4 _637_fa_layers_c : packoffset(c22);\n    float4 _637_fa_layers_d : packoffset(c23);\n    float4 _637_fa_ct_a : packoffset(c24);\n    float4 _637_fa_ct_b : packoffset(c25);\n    float4 _637_fa_ct_vpx : packoffset(c26);\n    float4 _637_fa_ct_vpy : packoffset(c27);\n    float4 _637_fa_ct_vpw : packoffset(c28);\n    float4 _637_fa_ct_fwd : packoffset(c29);\n    float4 _637_fa_tr_a : packoffset(c30);\n    float4 _637_fa_tr_b : packoffset(c31);\n    float4 _637_fa_probe_sh[9] : packoffset(c32);\n    float4 _637_fa_atlas : packoffset(c41);\n    float4 _637_fa_rpa_tile : packoffset(c42);\n    float4 _637_fa_rpa_pos : packoffset(c43);\n    float4 _637_fa_rpa_bx : packoffset(c44);\n    float4 _637_fa_rpa_by : packoffset(c45);\n    float4 _637_fa_rpa_bz : packoffset(c46);\n    float4 _637_fa_rpb_tile : packoffset(c47);\n    float4 _637_fa_rpb_pos : packoffset(c48);\n    float4 _637_fa_rpb_bx : packoffset(c49);\n    float4 _637_fa_rpb_by : packoffset(c50);\n    float4 _637_fa_rpb_bz : packoffset(c51);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2304_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2304_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2304_fa_shadow_info[4] : packoffset(c20);\n    float4 _2304_fa_shadow_split : packoffset(c24);\n    float4 _2304_fa_shadow_cfg : packoffset(c25);\n    float4 _2304_fa_shadow_bias : packoffset(c26);\n    float4 _2304_fa_shadow_eye : packoffset(c27);\n    float4 _2304_fa_shadow_fwd : packoffset(c28);\n    float4 _2304_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _7341_alphaCutoff : packoffset(c0);\n    float _7341_fa_pad0 : packoffset(c0.y);\n    float _7341_fa_pad1 : packoffset(c0.z);\n    float _7341_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1575 = _637_fa_cl_info.x < 0.0f;\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = _637_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    bool _1590;\n    if (!_1582)\n    {\n        _1590 = _637_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1590 = _1582;\n    }\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = _637_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = _637_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    if (_1604)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1614 = float4(world_pos, 1.0f);\n    float _1620 = dot(_637_fa_cl_vpw, _1614);\n    if (!(_1620 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1642 = float2(dot(_637_fa_cl_vpx, _1614), dot(_637_fa_cl_vpy, _1614)) / _1620.xx;\n    int _1646 = int(_637_fa_cl_grid.x);\n    int _1650 = int(_637_fa_cl_grid.y);\n    int param = (int(_637_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_637_fa_cl_fwd.xyz, world_pos) + _637_fa_cl_fwd.w, _637_fa_cl_grid.w) / _637_fa_cl_grid.w) * _637_fa_cl_grid.z)), 0, int(_637_fa_cl_info.y) - 1) * _1650) + clamp(int(floor(((_1642.y * 0.5f) + 0.5f) * _637_fa_cl_grid.y)), 0, _1650 - 1)) * _1646)) + clamp(int(floor(((_1642.x * 0.5f) + 0.5f) * _637_fa_cl_grid.x)), 0, _1646 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1726 = fa_cluster_texel(param);\n    return int2(int(_1726.x), int(_1726.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_637_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5781 = fa_cluster_lookup(param);\n    fa_cl_slot = _5781.x;\n    fa_cl_local = _5781.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6925 = fa_linear_to_srgb(param);\n        c = _6925;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6933 = fa_srgb_to_linear(param_1);\n            c = _6933;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _519;\n    if (i.front_facing)\n    {\n        _519 = i.world_normal;\n    }\n    else\n    {\n        _519 = -i.world_normal;\n    }\n    float3 _543 = normalize(i.world_tangent.xyz - (_519 * dot(_519, i.world_tangent.xyz)));\n    float3 _570 = normalize(((_543 * m.x) + ((cross(_519, _543) * i.world_tangent.w) * m.y)) + (_519 * m.z));\n    float3 _573;\n    if (i.front_facing)\n    {\n        _573 = _570;\n    }\n    else\n    {\n        _573 = -_570;\n    }\n    return _573;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _637_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6964 = fa_tex_fix(param_2, param_3);\n    float4 _8598 = base_t;\n    _8598.x = _6964.x;\n    _8598.y = _6964.y;\n    _8598.z = _6964.z;\n    base_t = _8598;\n    float4 _6978 = (_8598 * _637_fa_base_color) * i.vertex_color;\n    float3 _8382 = i.world_normal;\n    if (_637_fa_maps.z > 0.5f)\n    {\n        float param_4 = _637_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7010 = fa_tex_fix(param_6, param_7);\n        float3 _7013 = (_7010 * 2.0f) - 1.0f.xxx;\n        float2 _7018 = _7013.xy * _637_fa_maps.x;\n        float3 _8606 = _7013;\n        _8606.x = _7018.x;\n        _8606.y = _7018.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _8606;\n        _8382 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _637_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7046 = fa_tex_fix(param_12, param_13);\n    float4 _8609 = mrt;\n    _8609.x = _7046.x;\n    _8609.y = _7046.y;\n    _8609.z = _7046.z;\n    mrt = _8609;\n    float4 _7074 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _637_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7074.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7085 = fa_tex_fix(param_16, param_17);\n    float param_18 = _637_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7115 = fa_tex_fix(param_20, param_21);\n    float _8387 = _637_fa_layers_a.x;\n    float _8388 = _637_fa_layers_a.y;\n    float _8391 = _637_fa_layers_a.z;\n    float _8390 = _637_fa_layers_b.w;\n    float _8393 = _637_fa_layers_c.x;\n    if (_637_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_637_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _8387 *= _7085.y;\n            _8388 *= _7085.z;\n            _8390 *= _7074.w;\n        }\n        if (_637_fa_layers_c.z > 1.5f)\n        {\n            _8391 *= mrt.x;\n            _8393 *= mrt.w;\n        }\n    }\n    Surface _8420 = { _6978.xyz, _6978.w, _8382, clamp(_637_fa_pbr.x * _7046.z, 0.0f, 1.0f), clamp(_637_fa_pbr.y * _7046.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_637_fa_maps.y * (_7085.x - 1.0f)), _637_fa_emissive.xyz + (_637_fa_model_emissive.xyz * _7115), _8387, _8388, _637_fa_layers_b.xyz, _8390, _8391, _637_fa_layers_a.w, _8393, _637_fa_layers_c.y, _637_fa_layers_d.xyz, _637_fa_tr_a.x, _637_fa_tr_a.y, _637_fa_tr_b.xyz, _637_fa_tr_a.z };\n    return _8420;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1806 = rect.zw - rect.xy;\n    float2 _1810 = _1806 * atlas;\n    float2 _1814 = ddx * _1810;\n    float2 _1818 = ddy * _1810;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1806), clamp(0.5f * log2(max(max(dot(_1814, _1814), dot(_1818, _1818)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1851 = _637_fa_counts.y < 0.5f;\n    bool _1858;\n    if (!_1851)\n    {\n        _1858 = _637_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1858 = _1851;\n    }\n    if (_1858)\n    {\n        return;\n    }\n    float3 _1864 = ddx(world_pos);\n    float3 _1867 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1871 = fa_cluster_texel(param);\n    int _1875 = int(_1871.w);\n    if (_1875 < 1)\n    {\n        return;\n    }\n    int _1885 = int(_637_fa_counts.y + 0.5f);\n    int param_1 = _1885;\n    float4 _1889 = fa_light_texel(param_1);\n    float2 _1892 = _1889.yz;\n    int _1896 = int(_1889.w);\n    int param_2 = _1885 + 1;\n    float4 _1901 = fa_light_texel(param_2);\n    float _1902 = _1901.x;\n    int _1908 = int(_637_fa_counts.w + 0.5f) - 1;\n    int _1912 = int(_1871.z);\n    float3 _2177;\n    for (int k = 0; k < _1875; k++)\n    {\n        int _1925 = _1912 + k;\n        int param_3 = _1896 + (_1925 >> 2);\n        int _1942 = (_1885 + 2) + (int(fa_light_texel(param_3)[_1925 & 3]) * 7);\n        int param_4 = _1942 + 6;\n        float4 _1947 = fa_light_texel(param_4);\n        if (((int(_1947.w + 0.5f) >> _1908) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1942;\n        float4 _1962 = fa_light_texel(param_5);\n        int param_6 = _1942 + 1;\n        float4 _1967 = fa_light_texel(param_6);\n        int param_7 = _1942 + 2;\n        float4 _1972 = fa_light_texel(param_7);\n        float3 _1975 = _1962.xyz;\n        float _1980 = dot(_1975, world_pos) + _1962.w;\n        float3 _1982 = _1967.xyz;\n        float _1987 = dot(_1982, world_pos) + _1967.w;\n        float3 _1989 = _1972.xyz;\n        float _1994 = dot(_1989, world_pos) + _1972.w;\n        bool _1999 = abs(_1980) > 0.5f;\n        bool _2007;\n        if (!_1999)\n        {\n            _2007 = abs(_1987) > 0.5f;\n        }\n        else\n        {\n            _2007 = _1999;\n        }\n        bool _2015;\n        if (!_2007)\n        {\n            _2015 = abs(_1994) > 0.5f;\n        }\n        else\n        {\n            _2015 = _2007;\n        }\n        if (_2015)\n        {\n            continue;\n        }\n        float _2030 = clamp(dot(geo_normal, normalize(_1989)) * _1947.z, 0.0f, 1.0f);\n        if (_2030 <= 0.0f)\n        {\n            continue;\n        }\n        float _2050 = (clamp((0.5f - abs(_1994)) * 10.0f, 0.0f, 1.0f) * _2030) * _1947.x;\n        float2 _2058 = float2(_1980 + 0.5f, 0.5f - _1987);\n        float2 _2068 = float2(dot(_1975, _1864), dot(_1982, _1864));\n        float2 _2078 = float2(dot(_1975, _1867), dot(_1982, _1867));\n        int param_8 = _1942 + 5;\n        float4 _2083 = fa_light_texel(param_8);\n        int param_9 = _1942 + 3;\n        float4 _2088 = fa_light_texel(param_9);\n        int param_10 = _1942 + 4;\n        float4 _2093 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2083.xyz;\n        bool _2103 = _2088.z > _2088.x;\n        if (_2103)\n        {\n            float4 param_11 = _2088;\n            float2 param_12 = _2058;\n            float2 param_13 = _1892;\n            float2 param_14 = _2068;\n            float2 param_15 = _2078;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1902 > 0.5f) && (_1902 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2129 = fa_dc_to_linear(param_16);\n                float4 _8470 = tx;\n                _8470.x = _2129.x;\n                _8470.y = _2129.y;\n                _8470.z = _2129.z;\n                tx = _8470;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2050 * tex_a) * _2083.w, 0.0f, 1.0f).xxx);\n        if (_2093.z > _2093.x)\n        {\n            float4 param_17 = _2093;\n            float2 param_18 = _2058;\n            float2 param_19 = _1892;\n            float2 param_20 = _2068;\n            float2 param_21 = _2078;\n            float4 _2173 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1902 > 1.5f)\n            {\n                float3 param_22 = _2173.xyz;\n                float3 _2183 = fa_dc_to_srgb(param_22);\n                _2177 = _2183;\n            }\n            else\n            {\n                _2177 = _2173.xyz;\n            }\n            float3 _2192 = (_2177 * 2.0f) - 1.0f.xxx;\n            float2 _2197 = _2192.xy * _1947.y;\n            float3 _2219 = (normalize(_1975) * _2197.x) + (normalize(_1982) * _2197.y);\n            float3 _2222 = normalize(normal);\n            normal = normalize(lerp(_2222, normalize((_2222 * max(_2192.z, 0.0500000007450580596923828125f)) + (_2219 - (_2222 * dot(_2222, _2219)))), clamp(_2050 * (_2103 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4246 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4253 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4256 = int(_4246);\n    int _4259 = int(_4253);\n    float _4269 = _4253 - float(_4259);\n    int _4324 = (_4256 * 9) + _4259;\n    int _4344 = ((_4256 + 1) * 9) + _4259;\n    return lerp(lerp(_4320[_4324], _4320[_4324 + 1], _4269), lerp(_4320[_4344], _4320[_4344 + 1], _4269), _4246 - float(_4256));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _8305 = false;\n    float _8306 = 1.0f;\n    float _8307 = 1.0f;\n    float _8308 = 1.0f;\n    float _8309 = 0.0f;\n    float _8310 = 0.0f;\n    float _8311 = 0.0f;\n    float _8312 = 0.0f;\n    float _8314 = 1.0f;\n    bool _8315 = false;\n    float3 _8316 = 0.0f.xxx;\n    float _8317 = 1.0f;\n    float _8318 = 1.0f;\n    float _8319 = 1.0f;\n    float _8320 = 0.0f;\n    float _8321 = 0.0f;\n    float3 _8322 = float3(1.0f, 0.0f, 0.0f);\n    float3 _8323 = float3(0.0f, 0.0f, 1.0f);\n    float _8324 = 1.0f;\n    float _8325 = 1.0f;\n    float _4395 = clamp(s.specular, 0.0f, 1.0f);\n    float _4399 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4404 = (_4395 != 1.0f) || (_4399 != 1.5f);\n    bool _4413;\n    if (!_4404)\n    {\n        _4413 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4413 = _4404;\n    }\n    if (_4413)\n    {\n        float _4421 = (_4399 - 1.0f) / (_4399 + 1.0f);\n        f0 = lerp(min((_4421 * _4421).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4395, s.albedo, metallic.xxx);\n        _8306 = lerp(_4395, 1.0f, metallic);\n        _8305 = true;\n    }\n    float _4448 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4448 > 0.0f)\n    {\n        float _4456 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _8309 = _4448;\n        _8310 = _4456;\n        float _4463 = _4456 * _4456;\n        _8311 = _4463;\n        _8312 = _4463 * _4463;\n        float _4475 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _8314 = _4475;\n        _8307 = 1.0f - (_4448 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4475, 0.0f, 1.0f), 5.0f))));\n        _8305 = true;\n    }\n    float3 _4494 = max(s.sheen_color, 0.0f.xxx);\n    float _4503 = max(_4494.x, max(_4494.y, _4494.z));\n    if (_4503 > 0.0f)\n    {\n        float _4511 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _8315 = true;\n        _8316 = _4494;\n        _8317 = _4511;\n        _8318 = _4511 * _4511;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4511;\n        float _4528 = fa_sheen_albedo(param, param_1);\n        _8320 = _4528;\n        _8319 = 1.0f - min(_4503 * _4528, 1.0f);\n        _8305 = true;\n    }\n    _8308 = _8307 * _8319;\n    float _4547 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4547 != 0.0f)\n    {\n        float3 _4562 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4562;\n        if (dot(_4562, _4562) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4574 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4574.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4574.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4574.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4578 = t;\n        float3 _4579 = normalize(_4578);\n        t = _4579;\n        float3 _4604 = normalize((_4579 * cos(s.anisotropy_rotation)) + ((cross(n, _4579) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _8322 = _4604;\n        _8323 = cross(n, _4604);\n        float _4614 = roughness * roughness;\n        float _4620 = lerp(_4614, 1.0f, _4547 * _4547);\n        bool _4622 = _4547 > 0.0f;\n        _8324 = _4622 ? _4620 : _4614;\n        _8325 = _4622 ? _4614 : _4620;\n        _8321 = _4547;\n        _8305 = true;\n    }\n    FaLayers _8347 = { _8305, _8306, _8307, _8308, _8309, _8310, _8311, _8312, i.world_normal, _8314, _8315, _8316, _8317, _8318, _8319, _8320, _8321, _8322, _8323, _8324, _8325 };\n    return _8347;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3476_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3476_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_637_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3417 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3417;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4027 = (1.0f - _637_fa_rpa_tile.w) - _637_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4032 = _637_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4027 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4032)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _637_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4027;\n            }\n        }\n        else\n        {\n            amb = _637_fa_ambient.xyz * _4027;\n        }\n    }\n    bool _4083 = _637_fa_rpa_tile.w > 0.0f;\n    if (_4083)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _637_fa_rpa_tile.xy;\n            float param_4 = _637_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _637_fa_rpa_tile.w);\n        }\n    }\n    bool _4114 = _637_fa_rpb_tile.w > 0.0f;\n    if (_4114)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _637_fa_rpb_tile.xy;\n            float param_7 = _637_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _637_fa_rpb_tile.w);\n        }\n    }\n    if ((_4032 || _4083) || _4114)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_637_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _637_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_637_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_637_fa_cl_info.x) + int(_637_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_637_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5751;\n    if (fa_lm.z > 0.5f)\n    {\n        _5751 = 0.0f;\n    }\n    else\n    {\n        _5751 = 1.0f - clamp(_637_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5762 = _5751 < 1.0f;\n    bool _5768;\n    if (_5762)\n    {\n        int param = li;\n        _5768 = fa_light_baked(param);\n    }\n    else\n    {\n        _5768 = _5762;\n    }\n    return _5768 ? _5751 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _705_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _705_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _824 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _837 = (c - (ru * hx)) - p;\n        float3 _843 = ru * (2.0f * hx);\n        float _849 = max(dot(_843, _843), 9.9999999392252902907785028219223e-09f);\n        float _853 = dot(_837, _843);\n        float t = clamp((-_853) / _849, 0.0f, 1.0f);\n        if (_824)\n        {\n            float _868 = dot(r, _843);\n            float _874 = _849 - (_868 * _868);\n            if (abs(_874) > (9.9999997473787516355514526367188e-06f * _849))\n            {\n                t = clamp(((dot(r, _837) * _868) - _853) / _874, 0.0f, 1.0f);\n            }\n        }\n        return (p + _837) + (_843 * t);\n    }\n    float3 q = p;\n    float _906 = dot(r, axis);\n    bool _914;\n    if (_824)\n    {\n        _914 = abs(_906) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _914 = _824;\n    }\n    if (_914)\n    {\n        float _924 = dot(c - p, axis) / _906;\n        if (_924 > 0.0f)\n        {\n            q = p + (r * _924);\n        }\n    }\n    float3 _937 = q - c;\n    float2 xy = float2(dot(_937, ru), dot(_937, uu));\n    if (shape > 0.5f)\n    {\n        float _952 = length(xy);\n        if (_952 > hx)\n        {\n            xy *= (hx / _952);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _585 = abs(d);\n    float _587 = _585.x;\n    float _589 = _585.y;\n    bool _590 = _587 >= _589;\n    bool _598;\n    if (_590)\n    {\n        _598 = _587 >= _585.z;\n    }\n    else\n    {\n        _598 = _590;\n    }\n    int _599;\n    if (_598)\n    {\n        _599 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _614;\n        if (_589 >= _585.z)\n        {\n            _614 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _614 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _599 = _614;\n    }\n    return _599;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _744 = dot(d, right);\n    float _748 = dot(d, up);\n    float _759;\n    if (((_744 * _744) + (_748 * _748)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _759 = atan2(_748, _744) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _759 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_759 - floor(_759)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _990 = fa_light_base(param);\n    bool _994 = _637_fa_ambient.w > 4.5f;\n    int param_1 = _990;\n    float4 _998 = fa_light_texel(param_1);\n    int param_2 = _990 + 1;\n    float4 _1003 = fa_light_texel(param_2);\n    float _1006 = _1003.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1018 = _994 && (_1006 > 2.5f);\n    fa_light_is_area = _1018;\n    bool _1020 = _1006 < 0.5f;\n    float3 l;\n    if (_1020)\n    {\n        l = normalize(_998.xyz);\n        if (_994)\n        {\n            int param_3 = _990 + 6;\n            float4 _1034 = fa_light_texel(param_3);\n            if (_1034.z > 0.5f)\n            {\n                int param_4 = _990 + 4;\n                float4 _1044 = fa_light_texel(param_4);\n                int param_5 = _990 + 5;\n                float4 _1049 = fa_light_texel(param_5);\n                float2 param_6 = _1034.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1044.xyz) * _1044.w, (-dot(world_pos, _1049.xyz)) * _1049.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1079 = _998.xyz;\n        float3 _1081 = _1079 - world_pos;\n        float3 to_light = _1081;\n        float _1084 = length(_1081);\n        float reach = _1084;\n        bool front = true;\n        if (_1018)\n        {\n            int param_8 = _990 + 7;\n            reach = max(_1084 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _990 + 4;\n            float4 _1108 = fa_light_texel(param_9);\n            int param_10 = _990 + 5;\n            float4 _1113 = fa_light_texel(param_10);\n            int param_11 = _990 + 6;\n            float4 _1118 = fa_light_texel(param_11);\n            float _1119 = _1118.w;\n            int param_12 = _990 + 2;\n            float3 _1126 = normalize(fa_light_texel(param_12).xyz);\n            bool _1128 = _1119 > 1.5f;\n            bool _1136;\n            if (!_1128)\n            {\n                _1136 = dot(_1126, to_light) < 0.0f;\n            }\n            else\n            {\n                _1136 = _1128;\n            }\n            front = _1136;\n            float3 r = 0.0f.xxx;\n            float3 _1145 = _637_fa_camera_pos.xyz - world_pos;\n            bool _1149 = dot(n, n) > 0.5f;\n            bool _1157;\n            if (_1149)\n            {\n                _1157 = dot(_1145, _1145) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1157 = _1149;\n            }\n            if (_1157)\n            {\n                r = reflect(-normalize(_1145), normalize(n));\n            }\n            float3 param_13 = _1079;\n            float3 param_14 = _1126;\n            float3 param_15 = _1108.xyz;\n            float3 param_16 = _1113.xyz;\n            float param_17 = _1108.w;\n            float param_18 = _1113.w;\n            float param_19 = _1119;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1193 = length(to_light);\n        dist = _1193;\n        l = to_light / max(_1193, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1207 = reach / max(_998.w, 0.001000000047497451305389404296875f);\n        float _1213 = clamp(1.0f - (_1207 * _1207), 0.0f, 1.0f);\n        float _1215;\n        if (front)\n        {\n            _1215 = _1213 * _1213;\n        }\n        else\n        {\n            _1215 = 0.0f;\n        }\n        atten = _1215;\n        bool _1226 = _1006 < 2.5f;\n        if ((_1006 > 1.5f) && _1226)\n        {\n            int param_22 = _990 + 2;\n            float4 _1234 = fa_light_texel(param_22);\n            float _1244 = _1234.w;\n            int param_23 = _990 + 3;\n            float4 _1249 = fa_light_texel(param_23);\n            float _1250 = _1249.x;\n            float cos_inner = _1250;\n            if (_1250 > 1.5f)\n            {\n                cos_inner = lerp(_1244, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1244, cos_inner, dot(-l, normalize(_1234.xyz)));\n        }\n        if (_994 && (_1006 < 1.5f))\n        {\n            int param_24 = _990 + 6;\n            float4 _1274 = fa_light_texel(param_24);\n            if (_1274.z > 0.5f)\n            {\n                float3 _1282 = -to_light;\n                int param_25 = _990 + 4;\n                int param_26 = _990 + 5;\n                float3 _1296 = fa_light_texel(param_25).xyz;\n                float3 _1300 = fa_light_texel(param_26).xyz;\n                float3 _1309 = float3(dot(_1282, _1296), dot(_1282, _1300), dot(_1282, cross(_1296, _1300)));\n                float3 param_27 = _1309;\n                int _1313 = fa_cube_face(param_27);\n                int param_28 = _1313;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1340 = float2(dot(_1309, cross(param_29, param_30)), dot(_1309, param_30)) / max(dot(_1309, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1344 = _1313 / 3;\n                float2 param_31 = _1274.xy + (float2(float(_1313 - (_1344 * 3)), float(_1344)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1340.x), 0.5f - (0.5f * _1340.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _990 + 7;\n            float4 _1374 = fa_light_texel(param_33);\n            if (_1374.z > 0.5f)\n            {\n                int param_34 = _990 + 2;\n                int param_35 = _990 + 4;\n                int param_36 = _990 + 5;\n                float2 param_37 = _1374.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_994 && _1226)\n            {\n                int param_42 = _990 + 6;\n                float4 _1421 = fa_light_texel(param_42);\n                int param_43 = _990 + 7;\n                float4 _1426 = fa_light_texel(param_43);\n                bool _1429 = _1421.z > 0.5f;\n                bool _1436;\n                if (!_1429)\n                {\n                    _1436 = _1426.z > 0.5f;\n                }\n                else\n                {\n                    _1436 = _1429;\n                }\n                if (_1436)\n                {\n                    int param_44 = _990 + 2;\n                    float4 _1443 = fa_light_texel(param_44);\n                    float3 _1447 = normalize(_1443.xyz);\n                    int param_45 = _990 + 4;\n                    float4 _1452 = fa_light_texel(param_45);\n                    int param_46 = _990 + 5;\n                    float4 _1457 = fa_light_texel(param_46);\n                    if (_1429)\n                    {\n                        float3 _1465 = -to_light;\n                        float _1472 = _1443.w;\n                        float _1488 = 0.5f / max(dot(_1465, _1447) * (sqrt(max(1.0f - (_1472 * _1472), 0.0f)) / max(_1472, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1421.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1465, _1452.xyz) * _1488), 0.5f - (dot(_1465, _1457.xyz) * _1488));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1426.z > 0.5f)\n                    {\n                        float2 param_49 = _1426.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1447;\n                        float3 param_52 = _1452.xyz;\n                        float3 param_53 = _1457.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _8293 = _1003.xyz * atten;\n    if (_994)\n    {\n        _8293 *= fa_light_tint;\n    }\n    int _1557;\n    if (_1020)\n    {\n        _1557 = 0;\n    }\n    else\n    {\n        _1557 = ((_1006 > 1.5f) && (_1006 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _8304 = { l, _8293, atten, 1.0f, dist, _1557 };\n    return _8304;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2294;\n    if (i == 0)\n    {\n        _2294 = _2304_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2310;\n        if (i == 1)\n        {\n            _2310 = _2304_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2318;\n            if (i == 2)\n            {\n                _2318 = _2304_fa_shadow_split.z;\n            }\n            else\n            {\n                _2318 = _2304_fa_shadow_split.w;\n            }\n            _2310 = _2318;\n        }\n        _2294 = _2310;\n    }\n    return _2294;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2351 = fa_shadow_depth(param, param_1);\n    float _2355;\n    if (conv.x < 0.5f)\n    {\n        _2355 = _2351;\n    }\n    else\n    {\n        _2355 = (conv.y * conv.z) / (conv.z - (_2351 * (conv.z - conv.y)));\n    }\n    return _2355;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2282 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2282), sin(_2282)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2401 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2410;\n        if (k < 0.0f)\n        {\n            _2410 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2410 = k;\n        }\n        float _2430 = clamp((_2410 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2401;\n            float2 _2449 = fa_shadow_vogel(param_3, param_4, param_5) * _2430;\n            float2 param_6 = uv + (_2449 * _2304_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2461 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2461 < (zr - (length(_2449) * plane)))\n            {\n                sum += _2461;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2487 = sum / cnt;\n        float _2497;\n        if (k < 0.0f)\n        {\n            _2497 = (-k) / max(_2487, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2497 = k;\n        }\n        radius = clamp(((max(zr - _2487, 0.0f) * unit) * _2497) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2519 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2519; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2519;\n        float param_11 = _2401;\n        float2 _2538 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2538 * _2304_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2538) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2519);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2580 = max(_2304_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2585 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2591 = sqrt(1.0f - (_2585 * _2585));\n    float _2598 = min(_2591 / max(_2585, 0.20000000298023223876953125f), 4.0f);\n    float _2603;\n    if (_2304_fa_shadow_bias.y > 0.0f)\n    {\n        _2603 = _2304_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2603 = 1.5f * _2304_fa_shadow_info[ci].x;\n    }\n    float4 _2628 = mul(float4(world + (n * (_2603 * _2591)), 1.0f), _2304_fa_shadow_mat[ci]);\n    float _2635 = _2628.x;\n    bool _2638 = _2635 < _2304_fa_shadow_rect[ci].x;\n    bool _2647;\n    if (!_2638)\n    {\n        _2647 = _2635 > _2304_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2647 = _2638;\n    }\n    bool _2656;\n    if (!_2647)\n    {\n        _2656 = _2628.y < _2304_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2656 = _2647;\n    }\n    bool _2665;\n    if (!_2656)\n    {\n        _2665 = _2628.y > _2304_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2665 = _2656;\n    }\n    bool _2672;\n    if (!_2665)\n    {\n        _2672 = _2628.z > 1.0f;\n    }\n    else\n    {\n        _2672 = _2665;\n    }\n    if (_2672)\n    {\n        return -1.0f;\n    }\n    float _2680;\n    if (_2304_fa_shadow_bias.x > 0.0f)\n    {\n        _2680 = _2304_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2680 = 1.5f * _2304_fa_shadow_info[ci].x;\n    }\n    float2 param = _2628.xy;\n    float4 param_1 = _2304_fa_shadow_rect[ci];\n    float param_2 = _2628.z - ((_2680 * (1.0f + (0.5f * _2598))) / _2580);\n    float param_3 = _2304_fa_shadow_info[ci].x;\n    float param_4 = _2580;\n    float param_5 = _2580 * 0.25f;\n    float param_6 = ((_2304_fa_shadow_info[ci].x * min(_2598, 3.0f)) * 0.5f) / _2580;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2304_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2304_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_637_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3058 = int(_2304_fa_shadow_cfg.x + 0.5f);\n    if (_3058 < 1)\n    {\n        return 1.0f;\n    }\n    float _3073 = dot(world - _2304_fa_shadow_eye.xyz, _2304_fa_shadow_fwd.xyz);\n    int param = _3058 - 1;\n    if (_3073 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3085 = _3058 > 1;\n    bool _3092;\n    if (_3085)\n    {\n        _3092 = _3073 > _2304_fa_shadow_split.x;\n    }\n    else\n    {\n        _3092 = _3085;\n    }\n    if (_3092)\n    {\n        ci = 1;\n    }\n    bool _3096 = _3058 > 2;\n    bool _3103;\n    if (_3096)\n    {\n        _3103 = _3073 > _2304_fa_shadow_split.y;\n    }\n    else\n    {\n        _3103 = _3096;\n    }\n    if (_3103)\n    {\n        ci = 2;\n    }\n    bool _3107 = _3058 > 3;\n    bool _3114;\n    if (_3107)\n    {\n        _3114 = _3073 > _2304_fa_shadow_split.z;\n    }\n    else\n    {\n        _3114 = _3107;\n    }\n    if (_3114)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3058)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3140 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3140;\n        if (_3140 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2304_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3165;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3165 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3165 = _2304_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3184 = _2304_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3165, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3195 = clamp((_3073 - (fa_shadow_split_at(param_7) - _3184)) / _3184, 0.0f, 1.0f);\n        if (_3195 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3058)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3216 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3216;\n                if (_3216 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3195);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2738 = _637_fa_pbr.z < 0.5f;\n    bool _2745;\n    if (!_2738)\n    {\n        _2745 = _2304_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2745 = _2738;\n    }\n    if (_2745)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2304_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2758 = fa_light_texel(param);\n    float _2759 = _2758.x;\n    if (_2759 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2768 = int(_2759 + 0.5f);\n    int param_1 = _2768;\n    float4 _2772 = fa_light_texel(param_1);\n    int param_2 = _2768 + 1;\n    float4 _2777 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2780 = _2772.y;\n    if (_2780 > 0.0f)\n    {\n        float _2797 = 1.0f - smoothstep(0.75f * _2780, _2780, length(world - _2304_fa_shadow_eye.xyz));\n        fade = _2797;\n        if (_2797 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2772.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2821 = (_2768 + 2) + (face * 6);\n    int param_4 = _2821;\n    int param_5 = _2821 + 1;\n    int param_6 = _2821 + 3;\n    float4 _2835 = fa_light_texel(param_6);\n    int param_7 = _2821 + 4;\n    float4 _2840 = fa_light_texel(param_7);\n    int param_8 = _2821 + 5;\n    float4 _2845 = fa_light_texel(param_8);\n    float _2857 = _2845.x * max(dot(_2835, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2862 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2885 = clamp(dot(n, _2835.xyz), -1.0f, 1.0f);\n    float _2904 = min(sqrt(1.0f - (_2885 * _2885)) / max(abs(dot(n, world - lpos)) / max(dot(_2835, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2907 = _2777.y;\n    float _2909;\n    if (_2907 > 0.0f)\n    {\n        _2909 = _2907;\n    }\n    else\n    {\n        _2909 = 1.5f * _2857;\n    }\n    float4 _2929 = float4(world + (n * (_2909 * sqrt(1.0f - (_2862 * _2862)))), 1.0f);\n    float _2933 = dot(_2835, _2929);\n    float _2936 = _2845.y;\n    if (_2933 < _2936)\n    {\n        return 1.0f;\n    }\n    float2 _2951 = float2(dot(fa_light_texel(param_4), _2929), dot(fa_light_texel(param_5), _2929)) / _2933.xx;\n    float _2953 = _2951.x;\n    bool _2956 = _2953 < _2840.x;\n    bool _2965;\n    if (!_2956)\n    {\n        _2965 = _2953 > _2840.z;\n    }\n    else\n    {\n        _2965 = _2956;\n    }\n    bool _2974;\n    if (!_2965)\n    {\n        _2974 = _2951.y < _2840.y;\n    }\n    else\n    {\n        _2974 = _2965;\n    }\n    bool _2983;\n    if (!_2974)\n    {\n        _2983 = _2951.y > _2840.w;\n    }\n    else\n    {\n        _2983 = _2974;\n    }\n    if (_2983)\n    {\n        return 1.0f;\n    }\n    float _2989 = _2777.x;\n    float _2991;\n    if (_2989 > 0.0f)\n    {\n        _2991 = _2989;\n    }\n    else\n    {\n        _2991 = 1.5f * _2857;\n    }\n    float2 param_9 = _2951;\n    float4 param_10 = _2840;\n    float param_11 = _2933 - (_2991 * (1.0f + (0.5f * _2904)));\n    float param_12 = _2857;\n    float param_13 = 1.0f;\n    float param_14 = _2845.z * 0.25f;\n    float param_15 = (_2857 * min(_2904, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2936, _2845.z);\n    int param_17 = int(_2772.z + 0.5f);\n    float param_18 = _2772.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5132 = _637_fa_ct_a.x < 0.5f;\n    bool _5139;\n    if (!_5132)\n    {\n        _5139 = _2304_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5139 = _5132;\n    }\n    if (_5139)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2304_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5152 = fa_light_texel(param);\n    float _5153 = _5152.y;\n    float len = _5153;\n    if (_5153 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5165 = length(world - _637_fa_camera_pos.xyz);\n    float _5175 = 1.0f - smoothstep(0.5f * _637_fa_ct_b.x, _637_fa_ct_b.x, _5165);\n    if (_5175 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5181 = len;\n    float _5184 = min(_5181, 0.89999997615814208984375f * dist);\n    len = _5184;\n    float _5189 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5165);\n    float _5194 = _5189 + (0.5f * _5184);\n    float3 _5200 = world + (gn * _5189);\n    float _5202 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5266;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5217 = (float(k) + _5202) * 0.083333335816860198974609375f;\n        float3 _5225 = _5200 + (l * (_5217 * len));\n        float4 _5231 = float4(_5225, 1.0f);\n        float _5237 = dot(_637_fa_ct_vpw, _5231);\n        if (_5237 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5257 = float2(dot(_637_fa_ct_vpx, _5231), dot(_637_fa_ct_vpy, _5231)) / _5237.xx;\n        float _5261 = _5257.x * 0.5f;\n        float _5262 = _5261 + 0.5f;\n        if (_637_fa_ct_a.y > 0.5f)\n        {\n            _5266 = (_5257.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5266 = 0.5f - (_5257.y * 0.5f);\n        }\n        bool _5282 = _5262 < 0.0f;\n        bool _5289;\n        if (!_5282)\n        {\n            _5289 = _5262 >= 1.0f;\n        }\n        else\n        {\n            _5289 = _5282;\n        }\n        bool _5296;\n        if (!_5289)\n        {\n            _5296 = _5266 < 0.0f;\n        }\n        else\n        {\n            _5296 = _5289;\n        }\n        bool _5303;\n        if (!_5296)\n        {\n            _5303 = _5266 >= 1.0f;\n        }\n        else\n        {\n            _5303 = _5296;\n        }\n        if (_5303)\n        {\n            break;\n        }\n        float4 _5322 = fa_screen_tex.Load(int3(int2(float2(_5262, _5266) * _637_fa_ct_a.zw), 0));\n        if (_5322.w < 0.5f)\n        {\n            continue;\n        }\n        float _5341 = (dot(_637_fa_ct_fwd.xyz, _5225) + _637_fa_ct_fwd.w) - _5322.x;\n        if ((_5341 > _5189) && (_5341 < _5194))\n        {\n            occ = max(occ, (1.0f - (_5217 * _5217)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5262, 0.5f - _5261), min(_5266, 1.0f - _5266))));\n        }\n    }\n    return 1.0f - (occ * _5175);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5807 = fa_baked_keep(param);\n    if (_5807 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _8360 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _8360;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5833 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _8362 = _5833.color;\n    float _8363 = _5833.attenuation;\n    float _8364 = _5833.shadow;\n    bool _5836 = _5833.type == 0;\n    if (_5836 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5833.direction;\n        float _5847 = fa_shadow_factor(param_5, param_6);\n        _8364 = _5847;\n        _8362 *= _5847;\n    }\n    else\n    {\n        bool _5858 = _5833.type != 0;\n        bool _5864;\n        if (_5858)\n        {\n            _5864 = _8363 > 0.0f;\n        }\n        else\n        {\n            _5864 = _5858;\n        }\n        if (_5864)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5833.direction;\n            float _5883 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8364 = _5883;\n            _8362 *= _5883;\n        }\n    }\n    bool _5893 = _637_fa_ct_a.x > 0.5f;\n    bool _5899;\n    if (_5893)\n    {\n        _5899 = _8363 > 0.0f;\n    }\n    else\n    {\n        _5899 = _5893;\n    }\n    if (_5899)\n    {\n        float _5906;\n        if (_5836)\n        {\n            _5906 = 1000000000.0f;\n        }\n        else\n        {\n            _5906 = _5833._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5833.direction;\n        float param_18 = _5906;\n        float _5924 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8364 *= _5924;\n        _8362 *= _5924;\n    }\n    float _5937 = _8363;\n    float _5938 = _5937 * _5807;\n    _8363 = _5938;\n    float3 _5942 = _8362;\n    float3 _5943 = _5942 * _5807;\n    _8362 = _5943;\n    LightSample _8379 = { _5833.direction, _5943, _5938, _8364, _5833._distance, _5833.type };\n    return _8379;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5977 = v - (n * dot(v, n));\n    float3 t = _5977;\n    float _5981 = dot(_5977, _5977);\n    float l2 = _5981;\n    if (_5981 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5991;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5991 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5991 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5991;\n        l2 = dot(_5991, _5991);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6026 = dot(a, a);\n    float _6030 = dot(b, b);\n    if ((_6026 < 1.0000000195414813782625560981111e-24f) || (_6030 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6044 = a * rsqrt(_6026);\n    float3 _6049 = b * rsqrt(_6030);\n    float _6053 = dot(_6044, _6049);\n    float _6056 = abs(_6053);\n    float g = (((((((((((0.0416471660137176513671875f * _6056) - 0.1924748718738555908203125f) * _6056) + 0.4179156124591827392578125f) * _6056) - 0.616057217121124267578125f) * _6056) + 0.777722418308258056640625f) * _6056) - 0.999542415142059326171875f) * _6056) + 1.570791721343994140625f;\n    if (_6053 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6053 * _6053), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6044, _6049) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6113 = a.z > 0.0f;\n    bool _6117 = b.z > 0.0f;\n    if (_6113 && _6117)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6113 != _6117)\n        {\n            float3 _6152 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6152.z = 0.0f;\n            if (_6113)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6152;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6152;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6152;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6152;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6201 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6227 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6253 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6279 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6201;\n    float3 param_1 = _6227;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6227;\n    float3 param_7 = _6253;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6253;\n    float3 param_13 = _6279;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6279;\n    float3 param_19 = _6201;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6428 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6452 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6468 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6428;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6452;\n    float4 param_9 = m;\n    float3 param_10 = _6428;\n    float3 param_11 = _6452;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6468;\n    float4 param_14 = m;\n    float3 param_15 = _6428;\n    float3 param_16 = _6468;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6526 = fa_light_base(param);\n    int param_1 = _6526;\n    int param_2 = _6526 + 1;\n    int param_3 = _6526 + 2;\n    int param_4 = _6526 + 4;\n    float4 _6548 = fa_light_texel(param_4);\n    int param_5 = _6526 + 5;\n    float4 _6553 = fa_light_texel(param_5);\n    int param_6 = _6526 + 6;\n    float4 _6558 = fa_light_texel(param_6);\n    float _6559 = _6558.w;\n    float3 _6564 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6566 = _6559 < 1.5f;\n    bool _6573;\n    if (_6566)\n    {\n        _6573 = dot(normalize(fa_light_texel(param_3).xyz), _6564) >= 0.0f;\n    }\n    else\n    {\n        _6573 = _6566;\n    }\n    if (_6573)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6582 = (_6559 > 0.5f) && _6566;\n    float _6586 = _6582 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6589 = _6548.xyz;\n    float _6591 = _6548.w;\n    float3 _6597 = _6553.xyz;\n    float _6599 = _6553.w;\n    float3 up = _6597 * (_6599 * _6586);\n    float _6605;\n    if (_6582)\n    {\n        _6605 = (3.1415927410125732421875f * _6591) * _6591;\n    }\n    else\n    {\n        _6605 = (4.0f * _6591) * _6599;\n    }\n    if (_6559 > 1.5f)\n    {\n        float3 _6631 = cross(_6589, -_6564);\n        float3 perp = _6631;\n        float _6635 = dot(_6631, _6631);\n        float3 _6638;\n        if (_6635 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6638 = perp * rsqrt(_6635);\n        }\n        else\n        {\n            _6638 = _6597;\n        }\n        perp = _6638;\n        up = _6638 * _6599;\n    }\n    float _6659 = max(_6605, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6669 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6669;\n    float3 param_10 = n;\n    float3 param_11 = _6564;\n    float3 _6677 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6669;\n    float3 param_13 = n;\n    float3 param_14 = _6589 * (_6591 * _6586);\n    float3 _6685 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6669;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6693 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6559;\n    float3 param_20 = _6677;\n    float3 param_21 = _6685;\n    float3 param_22 = _6693;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6712 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6712;\n    float2 param_26 = _6712 + float2(64.0f, 0.0f);\n    float4 _6722 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6559;\n    float3 param_29 = _6677;\n    float3 param_30 = _6685;\n    float3 param_31 = _6693;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6722.x) + ((f90.xxx - f0) * _6722.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6564, _6564)) + _6659) / _6659) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4869 = 1.0f / alpha;\n    return ((2.0f + _4869) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4869)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4904 = max(dot(L.nc, l), 0.0f);\n    float _4910 = max(dot(L.nc, h), 0.0f);\n    float _4919 = ((_4910 * _4910) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4919) * _4919)) * (0.5f / max(lerp((2.0f * _4904) * L.coat_ndv, _4904 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4904)) * _4904;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6790;\n    if (L.sheen_on)\n    {\n        _6790 = L.sheen_scale;\n    }\n    else\n    {\n        _6790 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6790);\n    float3 _6803 = normalize(l + v);\n    int param_10 = li;\n    float3 _6814 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6823 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6803), 0.0f);\n        float param_13 = _6823;\n        float param_14 = ndv;\n        result += ((L.sheen * _6814) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6823)) * _6823) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6803;\n        float param_18 = max(dot(v, _6803), 0.0f);\n        result += (_6814 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4772 = tdh / at;\n    float _4776 = bdh / ab;\n    float _4788 = ((_4772 * _4772) + (_4776 * _4776)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4788) * _4788);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4968 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5047 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5047) * _5047);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4968);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4968));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4178 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4181 = _4178.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4181 * _4181, exp2((-9.27999973297119140625f) * ndv)) * _4181) + _4178.y)) + _4178.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3437 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3440 = _3437.x;\n    float _3442 = _3437.z;\n    float2 e = float2(_3440, _3442);\n    if (_3437.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3442)) * ((_3440 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3440)) * ((_3442 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3489;\n    if (lv == 0)\n    {\n        _3489 = 0.0f;\n    }\n    else\n    {\n        _3489 = res + 2.0f;\n    }\n    float _3499;\n    if (lv == 0)\n    {\n        _3499 = 0.0f;\n    }\n    else\n    {\n        _3499 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3489, _3499)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3544;\n    if (res > 64.5f)\n    {\n        _3544 = 5.0f;\n    }\n    else\n    {\n        _3544 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3559 = clamp(rough, 0.0f, 1.0f) * (_3544 - 1.0f);\n    int _3566 = int(min(floor(_3559), _3544 - 2.0f));\n    float _3571 = _3559 - float(_3566);\n    float3 param = d;\n    float2 _3575 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3566;\n    float2 param_4 = _3575;\n    float3 _3585 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3571 < 0.00200000009499490261077880859375f)\n    {\n        return _3585;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3566 + 1;\n    float2 param_8 = _3575;\n    return lerp(_3585, fa_probe_level(param_5, param_6, param_7, param_8), _3571.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3655 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3662 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3669 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3675 = dot(bx.xyz, d);\n    float _3679 = dot(by.xyz, d);\n    float _3683 = dot(bz.xyz, d);\n    float _3689;\n    if (_3675 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3689 = (1.0f - _3655) / _3675;\n    }\n    else\n    {\n        float _3703;\n        if (_3675 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3703 = ((-1.0f) - _3655) / _3675;\n        }\n        else\n        {\n            _3703 = 1000000015047466219876688855040.0f;\n        }\n        _3689 = _3703;\n    }\n    float tx = _3689;\n    float _3720;\n    if (_3679 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3720 = (1.0f - _3662) / _3679;\n    }\n    else\n    {\n        float _3733;\n        if (_3679 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3733 = ((-1.0f) - _3662) / _3679;\n        }\n        else\n        {\n            _3733 = 1000000015047466219876688855040.0f;\n        }\n        _3720 = _3733;\n    }\n    float ty = _3720;\n    float _3749;\n    if (_3683 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3749 = (1.0f - _3669) / _3683;\n    }\n    else\n    {\n        float _3762;\n        if (_3683 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3762 = ((-1.0f) - _3669) / _3683;\n        }\n        else\n        {\n            _3762 = 1000000015047466219876688855040.0f;\n        }\n        _3749 = _3762;\n    }\n    float _3774 = tx;\n    float _3777 = (_3774 > 0.0f) ? _3774 : 1000000015047466219876688855040.0f;\n    tx = _3777;\n    float _3778 = ty;\n    float _3781 = (_3778 > 0.0f) ? _3778 : 1000000015047466219876688855040.0f;\n    ty = _3781;\n    float _3791 = min(_3777, min(_3781, (_3749 > 0.0f) ? _3749 : 1000000015047466219876688855040.0f));\n    if (_3791 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3807 = (fa_world_pos + (d * _3791)) - posw.xyz;\n    float3 _3812;\n    if (dot(_3807, _3807) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3812 = normalize(_3807);\n    }\n    else\n    {\n        _3812 = d;\n    }\n    return _3812;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3858 = (1.0f - _637_fa_rpa_tile.w) - _637_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3858 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_637_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _637_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3887 = rough * rough;\n            float _3918 = 0.60000002384185791015625f * _3887;\n            base = lerp(lerp(_637_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_637_fa_env_horizon.xyz, _637_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3887)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3918, 0.0500000007450580596923828125f + _3918, d.y).xxx), ((_637_fa_env_sky.xyz + _637_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3887 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3858;\n    }\n    if (_637_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _637_fa_rpa_tile;\n        float4 param_5 = _637_fa_rpa_pos;\n        float4 param_6 = _637_fa_rpa_bx;\n        float4 param_7 = _637_fa_rpa_by;\n        float4 param_8 = _637_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3977 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3977 * _637_fa_rpa_tile.w);\n    }\n    if (_637_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _637_fa_rpb_tile;\n        float4 param_12 = _637_fa_rpb_pos;\n        float4 param_13 = _637_fa_rpb_bx;\n        float4 param_14 = _637_fa_rpb_by;\n        float4 param_15 = _637_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4009 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4009 * _637_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4655;\n        if (L.aniso >= 0.0f)\n        {\n            _4655 = L.b;\n        }\n        else\n        {\n            _4655 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4655, v), _4655), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4688 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4688.x) + (L.f90.xxx * _4688.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4743 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4743.x) + _4743.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4220 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4220.x) + _4220.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_637_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_637_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5445 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5449 = fa_xm_origin(param_1);\n    float2 _5455 = (uv * _5445) - 0.5f.xx;\n    float2 _5458 = frac(_5455);\n    float2 _5461 = floor(_5455);\n    float2 param_2 = _5445;\n    float2 param_3 = _5449;\n    float2 param_4 = _5461;\n    float2 param_5 = _5445;\n    float2 param_6 = _5449;\n    float2 param_7 = _5461 + float2(1.0f, 0.0f);\n    float2 param_8 = _5445;\n    float2 param_9 = _5449;\n    float2 param_10 = _5461 + float2(0.0f, 1.0f);\n    float2 param_11 = _5445;\n    float2 param_12 = _5449;\n    float2 param_13 = _5461 + 1.0f.xx;\n    float3 _5503 = _5458.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5503), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5503), _5458.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5522 = max(_637_fa_tr_b.w - 1.0f, 0.0f);\n    float _5526 = clamp(lod, 0.0f, _5522);\n    int _5530 = int(floor(_5526));\n    int param = _5530;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5540 = float(_5530);\n    float _5541 = _5526 - _5540;\n    bool _5543 = _5541 > 0.001000000047497451305389404296875f;\n    bool _5550;\n    if (_5543)\n    {\n        _5550 = _5540 < _5522;\n    }\n    else\n    {\n        _5550 = _5543;\n    }\n    if (_5550)\n    {\n        int param_2 = _5530 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5541.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5576 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _5576.x) + (f90.xxx * _5576.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _5604 = max(s.thickness, 0.0f);\n    bool _5609 = _5604 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5609)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5604);\n    }\n    bool _5634 = _637_fa_tr_a.w > 1.5f;\n    bool _5641;\n    if (!_5634)\n    {\n        _5641 = _637_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5641 = _5634;\n    }\n    if (_5641)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_5609)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5604);\n    }\n    float4 _5676 = float4(world, 1.0f);\n    float _5681 = dot(_637_fa_ct_vpw, _5676);\n    float2 uv = 0.5f.xx;\n    if (_5681 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5699 = float2(dot(_637_fa_ct_vpx, _5676), dot(_637_fa_ct_vpy, _5676)) / _5681.xx;\n        float _5707;\n        if (_637_fa_ct_a.y > 0.5f)\n        {\n            _5707 = (_5699.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5707 = 0.5f - (_5699.y * 0.5f);\n        }\n        uv = float2((_5699.x * 0.5f) + 0.5f, _5707);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_637_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2304_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3240 = int(_2304_fa_shadow_cfg.x + 0.5f);\n    float _3250 = dot(world - _2304_fa_shadow_eye.xyz, _2304_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3255 = _3240 > 0;\n    bool _3264;\n    if (_3255)\n    {\n        int param = _3240 - 1;\n        _3264 = _3250 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3264 = _3255;\n    }\n    if (_3264)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3270 = _3240 > 1;\n        bool _3277;\n        if (_3270)\n        {\n            _3277 = _3250 > _2304_fa_shadow_split.x;\n        }\n        else\n        {\n            _3277 = _3270;\n        }\n        if (_3277)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3283 = _3240 > 2;\n        bool _3290;\n        if (_3283)\n        {\n            _3290 = _3250 > _2304_fa_shadow_split.y;\n        }\n        else\n        {\n            _3290 = _3283;\n        }\n        if (_3290)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3296 = _3240 > 3;\n        bool _3303;\n        if (_3296)\n        {\n            _3303 = _3250 > _2304_fa_shadow_split.z;\n        }\n        else\n        {\n            _3303 = _3296;\n        }\n        if (_3303)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _8021 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8021 = -_8021;\n    }\n    float3 _7305 = normalize(_637_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _8034 = { fa_world_pos, _8021, fa_world_tangent, fa_uv, fa_vertex_color, _7305, gl_FrontFacing };\n    SurfaceInput param_1 = _8034;\n    Surface _7313 = fa_standard_surface(param_1);\n    float3 _8052 = _7313.albedo;\n    float _8053 = _7313.alpha;\n    float3 _8054 = _7313.normal;\n    float _8055 = _7313.metallic;\n    float _8056 = _7313.roughness;\n    float _8057 = _7313.occlusion;\n    float3 _8058 = _7313.emission;\n    float _8059 = _7313.clearcoat;\n    float _8060 = _7313.clearcoat_roughness;\n    float3 _8061 = _7313.sheen_color;\n    float _8062 = _7313.sheen_roughness;\n    float _8063 = _7313.anisotropy;\n    float _8064 = _7313.anisotropy_rotation;\n    float _8065 = _7313.specular;\n    float _8066 = _7313.ior;\n    float3 _8067 = _7313.specular_color;\n    float _8068 = _7313.transmission;\n    float _8069 = _7313.thickness;\n    float3 _8070 = _7313.attenuation_color;\n    float _8071 = _7313.attenuation_distance;\n    SurfaceInput _8042 = { fa_world_pos, _8021, fa_world_tangent, fa_uv, fa_vertex_color, _7305, gl_FrontFacing };\n    SurfaceInput param_2 = _8042;\n    Surface param_3 = _7313;\n    surface(param_2, param_3);\n    _8052 = param_3.albedo;\n    _8053 = param_3.alpha;\n    _8054 = param_3.normal;\n    _8055 = param_3.metallic;\n    _8056 = param_3.roughness;\n    _8057 = param_3.occlusion;\n    _8058 = param_3.emission;\n    _8059 = param_3.clearcoat;\n    _8060 = param_3.clearcoat_roughness;\n    _8061 = param_3.sheen_color;\n    _8062 = param_3.sheen_roughness;\n    _8063 = param_3.anisotropy;\n    _8064 = param_3.anisotropy_rotation;\n    _8065 = param_3.specular;\n    _8066 = param_3.ior;\n    _8067 = param_3.specular_color;\n    _8068 = param_3.transmission;\n    _8069 = param_3.thickness;\n    _8070 = param_3.attenuation_color;\n    _8071 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _8021;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8052 = param_6;\n    _8054 = param_7;\n    if (_8053 < _7341_alphaCutoff)\n    {\n        discard;\n    }\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_637_fa_emissive.w > 0.5f)\n    {\n        result = _8052;\n    }\n    else\n    {\n        float3 _7364 = normalize(_8054);\n        float _7371 = clamp(_8055, 0.0f, 1.0f);\n        float _7375 = clamp(_8056, 0.0500000007450580596923828125f, 1.0f);\n        float _7379 = _7375 * _7375;\n        float _7383 = _7379 * _7379;\n        float _7388 = max(dot(_7364, _7305), 9.9999997473787516355514526367188e-05f);\n        float _7394 = 1.0f - _7371;\n        float _7395 = clamp(_8068, 0.0f, 1.0f) * _7394;\n        float3 _7404 = (_8052 * _7394) * (1.0f - _7395);\n        float3 _7411 = lerp(0.039999999105930328369140625f.xxx, _8052, _7371.xxx);\n        float3 f0 = _7411;\n        SurfaceInput _8050 = { fa_world_pos, _8021, fa_world_tangent, fa_uv, fa_vertex_color, _7305, gl_FrontFacing };\n        SurfaceInput param_8 = _8050;\n        Surface _8153 = { _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066, _8067, _8068, _8069, _8070, _8071 };\n        Surface param_9 = _8153;\n        float3 param_10 = _7364;\n        float3 param_11 = _7305;\n        float param_12 = _7371;\n        float param_13 = _7375;\n        float3 param_14 = _7411;\n        FaLayers _7427 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _7364;\n        float3 lit = (fa_indirect_diffuse(param_15) * _7404) * _8057;\n        if (_7427.on)\n        {\n            lit *= _7427.base_scale;\n        }\n        int _7449 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7449; ln++)\n        {\n            int param_16 = ln;\n            int _7462 = fa_cl_light(param_16);\n            int param_17 = _7462;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _7462;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _8021;\n            LightSample _7478 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7486 = max(dot(_7364, _7478.direction), 0.0f);\n            float _7492 = _7478.attenuation * _7478.shadow;\n            float3 _7497 = normalize(_7478.direction + _7305);\n            float _7502 = max(dot(_7364, _7497), 0.0f);\n            float _7507 = max(dot(_7305, _7497), 0.0f);\n            bool _7514;\n            if (fa_light_is_area)\n            {\n                _7514 = !_7427.on;\n            }\n            else\n            {\n                _7514 = fa_light_is_area;\n            }\n            if (_7514)\n            {\n                int param_21 = _7462;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _7364;\n                float3 param_24 = _7305;\n                float3 param_25 = _7404;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _7375;\n                float param_29 = _7388;\n                float param_30 = _7492;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7427;\n                    int param_32 = _7462;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _7364;\n                    float3 param_35 = _7305;\n                    float3 param_36 = _7478.direction;\n                    float3 param_37 = _7404;\n                    float3 param_38 = f0;\n                    float param_39 = _7375;\n                    float param_40 = _7388;\n                    float param_41 = _7492;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7427.on)\n                    {\n                        FaLayers param_42 = _7427;\n                        float3 param_43 = _7404;\n                        float3 param_44 = f0;\n                        float3 param_45 = _7364;\n                        float3 param_46 = _7305;\n                        float3 param_47 = _7478.direction;\n                        float3 param_48 = _7497;\n                        float param_49 = _7486;\n                        float param_50 = _7388;\n                        float param_51 = _7502;\n                        float param_52 = _7507;\n                        float param_53 = _7379;\n                        float param_54 = _7383;\n                        int param_55 = _7462;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7492));\n                    }\n                    else\n                    {\n                        float _7620 = ((_7502 * _7502) * (_7383 - 1.0f)) + 1.0f;\n                        int param_56 = _7462;\n                        lit += (((_7404 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _7507, 5.0f))) * (((_7383 / ((3.1415927410125732421875f * _7620) * _7620)) * (0.5f / max(lerp((2.0f * _7486) * _7388, _7486 + _7388, _7379), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _7486))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7486 * _7492));\n                    }\n                }\n            }\n        }\n        if (_7427.on)\n        {\n            FaLayers param_57 = _7427;\n            float3 param_58 = _7364;\n            float3 param_59 = _7305;\n            float3 param_60 = f0;\n            float param_61 = _7375;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8057);\n        }\n        else\n        {\n            float3 param_62 = _7364;\n            float3 param_63 = _7305;\n            float3 param_64 = f0;\n            float param_65 = _7375;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8057);\n        }\n        if (_7395 > 0.0f)\n        {\n            float _7718;\n            if (_7427.on)\n            {\n                _7718 = _7427.f90;\n            }\n            else\n            {\n                _7718 = 1.0f;\n            }\n            float _7726;\n            if (_7427.on)\n            {\n                _7726 = _7427.base_scale;\n            }\n            else\n            {\n                _7726 = 1.0f;\n            }\n            Surface _8174 = { _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066, _8067, _8068, _8069, _8070, _8071 };\n            Surface param_66 = _8174;\n            float3 param_67 = _7364;\n            float3 param_68 = _7305;\n            float param_69 = _7375;\n            float3 param_70 = f0;\n            float param_71 = _7718;\n            float param_72 = _7726;\n            float param_73 = _7395;\n            float param_74 = fa_tr_blend;\n            float3 _7750 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7750;\n        }\n        result = lit;\n    }\n    float3 _7757 = result;\n    float3 _7758 = _7757 + _8058;\n    result = _7758;\n    float3 param_75 = _7758;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7767 = _637_fa_fog.w > 0.0f;\n    bool _7774;\n    if (!_7767)\n    {\n        _7774 = _637_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7774 = _7767;\n    }\n    if (_7774)\n    {\n        float3 _7783 = fa_world_pos - _637_fa_camera_pos.xyz;\n        float _7789 = dot(_7783, _637_fa_fog_c.xyz);\n        bool _7793 = _637_fa_fog_c.w > 0.5f;\n        float _7794;\n        if (_7793)\n        {\n            _7794 = _7789;\n        }\n        else\n        {\n            _7794 = length(_7783);\n        }\n        float _7806 = _7794 - _637_fa_fog_b.x;\n        if (_7806 > 0.0f)\n        {\n            float _7815 = _637_fa_fog.w * _7806;\n            float tau = _7815 * _7815;\n            if (_637_fa_fog_b.y > 0.0f)\n            {\n                float _7831;\n                if (_7793)\n                {\n                    _7831 = fa_world_pos.y - (_637_fa_fog_c.y * _7789);\n                }\n                else\n                {\n                    _7831 = _637_fa_camera_pos.y;\n                }\n                float _7852 = lerp(_7831, fa_world_pos.y, clamp(_637_fa_fog_b.x / _7794, 0.0f, 1.0f));\n                float _7856 = fa_world_pos.y - _7852;\n                float _7861 = _7852 - _637_fa_fog_b.z;\n                float _7866 = fa_world_pos.y - _637_fa_fog_b.z;\n                bool _7869 = _7861 <= 0.0f;\n                bool _7870 = !_7869;\n                bool _7876;\n                if (_7870)\n                {\n                    _7876 = _637_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7876 = _7869;\n                }\n                float _7877;\n                if (_7876)\n                {\n                    _7877 = _637_fa_fog_b.y;\n                }\n                else\n                {\n                    _7877 = _637_fa_fog_b.y * exp(-min(_637_fa_fog_b.w * _7861, 80.0f));\n                }\n                bool _7904;\n                if (_7870)\n                {\n                    _7904 = _637_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7904 = _7869;\n                }\n                float _7905;\n                if (_7904)\n                {\n                    _7905 = _637_fa_fog_b.y * _7861;\n                }\n                else\n                {\n                    _7905 = (_637_fa_fog_b.y * (1.0f - exp(-min(_637_fa_fog_b.w * _7861, 80.0f)))) / _637_fa_fog_b.w;\n                }\n                bool _7930 = _7866 <= 0.0f;\n                bool _7937;\n                if (!_7930)\n                {\n                    _7937 = _637_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7937 = _7930;\n                }\n                float _7938;\n                if (_7937)\n                {\n                    _7938 = _637_fa_fog_b.y * _7866;\n                }\n                else\n                {\n                    _7938 = (_637_fa_fog_b.y * (1.0f - exp(-min(_637_fa_fog_b.w * _7866, 80.0f)))) / _637_fa_fog_b.w;\n                }\n                float _7965;\n                if (abs(_7856) < 0.001000000047497451305389404296875f)\n                {\n                    _7965 = _7877;\n                }\n                else\n                {\n                    _7965 = (_7938 - _7905) / _7856;\n                }\n                tau += (_7806 * max(_7965, 0.0f));\n            }\n            result = lerp(result, _637_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _8001 = 1.0f - fa_tr_blend;\n        result /= _8001.xxx;\n        _8053 *= _8001;\n    }\n    fa_frag_color = float4(result, _8053);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_637",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2304",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_7341",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _800 = base_t;\n    _800.x = _239.x;\n    _800.y = _239.y;\n    _800.z = _239.z;\n    base_t = _800;\n    float4 _255 = (_800 * _227_fa_base_color) * i.vertex_color;\n    float3 _755 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _808 = _292;\n        _808.x = _297.x;\n        _808.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _808;\n        _755 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _811 = mrt;\n    _811.x = _326.x;\n    _811.y = _326.y;\n    _811.z = _326.z;\n    mrt = _811;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _760 = _227_fa_layers_a.x;\n    float _761 = _227_fa_layers_a.y;\n    float _764 = _227_fa_layers_a.z;\n    float _763 = _227_fa_layers_b.w;\n    float _766 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _760 *= _368.y;\n            _761 *= _368.z;\n            _763 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _764 *= mrt.x;\n            _766 *= mrt.w;\n        }\n    }\n    Surface _793 = { _255.xyz, _255.w, _755, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _760, _761, _227_fa_layers_b.xyz, _763, _764, _227_fa_layers_a.w, _766, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _793;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _650 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _650 = -_650;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _663 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _663;\n    Surface _556 = fa_standard_surface(param);\n    float3 _674 = _556.normal;\n    SurfaceInput _671 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _671;\n    Surface param_2 = _556;\n    surface(param_1, param_2);\n    _674 = param_2.normal;\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _577 = normalize(_674);\n    float3 _592 = normalize(float3(dot(fa_pre_r0, _577), dot(fa_pre_r1, _577), dot(fa_pre_r2, _577)));\n    float _604 = _592.z;\n    float2 e = _592.xy / ((abs(_592.x) + abs(_592.y)) + abs(_604)).xx;\n    if (_604 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 832,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _800 = base_t;\n    _800.x = _239.x;\n    _800.y = _239.y;\n    _800.z = _239.z;\n    base_t = _800;\n    float4 _255 = (_800 * _227_fa_base_color) * i.vertex_color;\n    float3 _755 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _808 = _292;\n        _808.x = _297.x;\n        _808.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _808;\n        _755 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _811 = mrt;\n    _811.x = _326.x;\n    _811.y = _326.y;\n    _811.z = _326.z;\n    mrt = _811;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _760 = _227_fa_layers_a.x;\n    float _761 = _227_fa_layers_a.y;\n    float _764 = _227_fa_layers_a.z;\n    float _763 = _227_fa_layers_b.w;\n    float _766 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _760 *= _368.y;\n            _761 *= _368.z;\n            _763 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _764 *= mrt.x;\n            _766 *= mrt.w;\n        }\n    }\n    Surface _793 = { _255.xyz, _255.w, _755, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _760, _761, _227_fa_layers_b.xyz, _763, _764, _227_fa_layers_a.w, _766, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _793;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _650 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _650 = -_650;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _663 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _663;\n    Surface _556 = fa_standard_surface(param);\n    float3 _674 = _556.normal;\n    SurfaceInput _671 = { fa_world_pos, _650, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _671;\n    Surface param_2 = _556;\n    surface(param_1, param_2);\n    _674 = param_2.normal;\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _577 = normalize(_674);\n    float3 _592 = normalize(float3(dot(fa_pre_r0, _577), dot(fa_pre_r1, _577), dot(fa_pre_r2, _577)));\n    float _604 = _592.z;\n    float2 e = _592.xy / ((abs(_592.x) + abs(_592.y)) + abs(_604)).xx;\n    if (_604 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 832,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _734 = base_t;\n    _734.x = _239.x;\n    _734.y = _239.y;\n    _734.z = _239.z;\n    base_t = _734;\n    float4 _255 = (_734 * _227_fa_base_color) * i.vertex_color;\n    float3 _695 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _742 = _292;\n        _742.x = _297.x;\n        _742.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _742;\n        _695 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _745 = mrt;\n    _745.x = _326.x;\n    _745.y = _326.y;\n    _745.z = _326.z;\n    mrt = _745;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _700 = _227_fa_layers_a.x;\n    float _701 = _227_fa_layers_a.y;\n    float _704 = _227_fa_layers_a.z;\n    float _703 = _227_fa_layers_b.w;\n    float _706 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _700 *= _368.y;\n            _701 *= _368.z;\n            _703 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _704 *= mrt.x;\n            _706 *= mrt.w;\n        }\n    }\n    Surface _733 = { _255.xyz, _255.w, _695, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _700, _701, _227_fa_layers_b.xyz, _703, _704, _227_fa_layers_a.w, _706, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _733;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _590 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _590 = -_590;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _603 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _603;\n    SurfaceInput _611 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _611;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 832,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_tr_a : packoffset(c30);\n    float4 _227_fa_tr_b : packoffset(c31);\n    float4 _227_fa_probe_sh[9] : packoffset(c32);\n    float4 _227_fa_atlas : packoffset(c41);\n    float4 _227_fa_rpa_tile : packoffset(c42);\n    float4 _227_fa_rpa_pos : packoffset(c43);\n    float4 _227_fa_rpa_bx : packoffset(c44);\n    float4 _227_fa_rpa_by : packoffset(c45);\n    float4 _227_fa_rpa_bz : packoffset(c46);\n    float4 _227_fa_rpb_tile : packoffset(c47);\n    float4 _227_fa_rpb_pos : packoffset(c48);\n    float4 _227_fa_rpb_bx : packoffset(c49);\n    float4 _227_fa_rpb_by : packoffset(c50);\n    float4 _227_fa_rpb_bz : packoffset(c51);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _567_alphaCutoff : packoffset(c0);\n    float _567_fa_pad0 : packoffset(c0.y);\n    float _567_fa_pad1 : packoffset(c0.z);\n    float _567_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _734 = base_t;\n    _734.x = _239.x;\n    _734.y = _239.y;\n    _734.z = _239.z;\n    base_t = _734;\n    float4 _255 = (_734 * _227_fa_base_color) * i.vertex_color;\n    float3 _695 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _742 = _292;\n        _742.x = _297.x;\n        _742.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _742;\n        _695 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _745 = mrt;\n    _745.x = _326.x;\n    _745.y = _326.y;\n    _745.z = _326.z;\n    mrt = _745;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _700 = _227_fa_layers_a.x;\n    float _701 = _227_fa_layers_a.y;\n    float _704 = _227_fa_layers_a.z;\n    float _703 = _227_fa_layers_b.w;\n    float _706 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _700 *= _368.y;\n            _701 *= _368.z;\n            _703 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _704 *= mrt.x;\n            _706 *= mrt.w;\n        }\n    }\n    Surface _733 = { _255.xyz, _255.w, _695, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _700, _701, _227_fa_layers_b.xyz, _703, _704, _227_fa_layers_a.w, _706, _227_fa_layers_c.y, _227_fa_layers_d.xyz, _227_fa_tr_a.x, _227_fa_tr_a.y, _227_fa_tr_b.xyz, _227_fa_tr_a.z };\n    return _733;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _590 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _590 = -_590;\n    }\n    float3 _551 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _603 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param = _603;\n    SurfaceInput _611 = { fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing };\n    SurfaceInput param_1 = _611;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _567_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 832,
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
