{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "hlsl5",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _45_offset : packoffset(c0);\n    float _45_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _145_fa_view_proj : packoffset(c0);\n    row_major float4x4 _145_fa_light_vp : packoffset(c4);\n    float4 _145_fa_uv_scale : packoffset(c8);\n    float4 _145_fa_time : packoffset(c9);\n    float4 _145_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _278 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145_fa_uv_scale.xy, color, position };\n    return _278;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _45_offset;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _145_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4285[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _602_fa_camera_pos : packoffset(c0);\n    float4 _602_fa_ambient : packoffset(c1);\n    float4 _602_fa_base_color : packoffset(c2);\n    float4 _602_fa_emissive : packoffset(c3);\n    float4 _602_fa_model_emissive : packoffset(c4);\n    float4 _602_fa_pbr : packoffset(c5);\n    float4 _602_fa_maps : packoffset(c6);\n    float4 _602_fa_fog : packoffset(c7);\n    float4 _602_fa_fog_b : packoffset(c8);\n    float4 _602_fa_fog_c : packoffset(c9);\n    float4 _602_fa_counts : packoffset(c10);\n    float4 _602_fa_env_sky : packoffset(c11);\n    float4 _602_fa_env_horizon : packoffset(c12);\n    float4 _602_fa_time : packoffset(c13);\n    float4 _602_fa_cl_vpx : packoffset(c14);\n    float4 _602_fa_cl_vpy : packoffset(c15);\n    float4 _602_fa_cl_vpw : packoffset(c16);\n    float4 _602_fa_cl_fwd : packoffset(c17);\n    float4 _602_fa_cl_grid : packoffset(c18);\n    float4 _602_fa_cl_info : packoffset(c19);\n    float4 _602_fa_layers_a : packoffset(c20);\n    float4 _602_fa_layers_b : packoffset(c21);\n    float4 _602_fa_layers_c : packoffset(c22);\n    float4 _602_fa_layers_d : packoffset(c23);\n    float4 _602_fa_ct_a : packoffset(c24);\n    float4 _602_fa_ct_b : packoffset(c25);\n    float4 _602_fa_ct_vpx : packoffset(c26);\n    float4 _602_fa_ct_vpy : packoffset(c27);\n    float4 _602_fa_ct_vpw : packoffset(c28);\n    float4 _602_fa_ct_fwd : packoffset(c29);\n    float4 _602_fa_probe_sh[9] : packoffset(c30);\n    float4 _602_fa_atlas : packoffset(c39);\n    float4 _602_fa_rpa_tile : packoffset(c40);\n    float4 _602_fa_rpa_pos : packoffset(c41);\n    float4 _602_fa_rpa_bx : packoffset(c42);\n    float4 _602_fa_rpa_by : packoffset(c43);\n    float4 _602_fa_rpa_bz : packoffset(c44);\n    float4 _602_fa_rpb_tile : packoffset(c45);\n    float4 _602_fa_rpb_pos : packoffset(c46);\n    float4 _602_fa_rpb_bx : packoffset(c47);\n    float4 _602_fa_rpb_by : packoffset(c48);\n    float4 _602_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2269_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2269_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2269_fa_shadow_info[4] : packoffset(c20);\n    float4 _2269_fa_shadow_split : packoffset(c24);\n    float4 _2269_fa_shadow_cfg : packoffset(c25);\n    float4 _2269_fa_shadow_bias : packoffset(c26);\n    float4 _2269_fa_shadow_eye : packoffset(c27);\n    float4 _2269_fa_shadow_fwd : packoffset(c28);\n    float4 _2269_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1540 = _602_fa_cl_info.x < 0.0f;\n    bool _1547;\n    if (!_1540)\n    {\n        _1547 = _602_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1547 = _1540;\n    }\n    bool _1555;\n    if (!_1547)\n    {\n        _1555 = _602_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1555 = _1547;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = _602_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    bool _1569;\n    if (!_1562)\n    {\n        _1569 = _602_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1569 = _1562;\n    }\n    if (_1569)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1579 = float4(world_pos, 1.0f);\n    float _1585 = dot(_602_fa_cl_vpw, _1579);\n    if (!(_1585 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1607 = float2(dot(_602_fa_cl_vpx, _1579), dot(_602_fa_cl_vpy, _1579)) / _1585.xx;\n    int _1611 = int(_602_fa_cl_grid.x);\n    int _1615 = int(_602_fa_cl_grid.y);\n    int param = (int(_602_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_602_fa_cl_fwd.xyz, world_pos) + _602_fa_cl_fwd.w, _602_fa_cl_grid.w) / _602_fa_cl_grid.w) * _602_fa_cl_grid.z)), 0, int(_602_fa_cl_info.y) - 1) * _1615) + clamp(int(floor(((_1607.y * 0.5f) + 0.5f) * _602_fa_cl_grid.y)), 0, _1615 - 1)) * _1611)) + clamp(int(floor(((_1607.x * 0.5f) + 0.5f) * _602_fa_cl_grid.x)), 0, _1611 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1691 = fa_cluster_texel(param);\n    return int2(int(_1691.x), int(_1691.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_602_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5383 = fa_cluster_lookup(param);\n    fa_cl_slot = _5383.x;\n    fa_cl_local = _5383.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6517 = fa_linear_to_srgb(param);\n        c = _6517;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6525 = fa_srgb_to_linear(param_1);\n            c = _6525;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _484;\n    if (i.front_facing)\n    {\n        _484 = i.world_normal;\n    }\n    else\n    {\n        _484 = -i.world_normal;\n    }\n    float3 _508 = normalize(i.world_tangent.xyz - (_484 * dot(_484, i.world_tangent.xyz)));\n    float3 _535 = normalize(((_508 * m.x) + ((cross(_484, _508) * i.world_tangent.w) * m.y)) + (_484 * m.z));\n    float3 _538;\n    if (i.front_facing)\n    {\n        _538 = _535;\n    }\n    else\n    {\n        _538 = -_535;\n    }\n    return _538;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _602_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6556 = fa_tex_fix(param_2, param_3);\n    float4 _8044 = base_t;\n    _8044.x = _6556.x;\n    _8044.y = _6556.y;\n    _8044.z = _6556.z;\n    base_t = _8044;\n    float4 _6570 = (_8044 * _602_fa_base_color) * i.vertex_color;\n    float3 _7844 = i.world_normal;\n    if (_602_fa_maps.z > 0.5f)\n    {\n        float param_4 = _602_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6602 = fa_tex_fix(param_6, param_7);\n        float3 _6605 = (_6602 * 2.0f) - 1.0f.xxx;\n        float2 _6610 = _6605.xy * _602_fa_maps.x;\n        float3 _8052 = _6605;\n        _8052.x = _6610.x;\n        _8052.y = _6610.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _8052;\n        _7844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _602_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6638 = fa_tex_fix(param_12, param_13);\n    float4 _8055 = mrt;\n    _8055.x = _6638.x;\n    _8055.y = _6638.y;\n    _8055.z = _6638.z;\n    mrt = _8055;\n    float4 _6666 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _602_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6666.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6677 = fa_tex_fix(param_16, param_17);\n    float param_18 = _602_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6707 = fa_tex_fix(param_20, param_21);\n    float _7849 = _602_fa_layers_a.x;\n    float _7850 = _602_fa_layers_a.y;\n    float _7853 = _602_fa_layers_a.z;\n    float _7852 = _602_fa_layers_b.w;\n    float _7855 = _602_fa_layers_c.x;\n    if (_602_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_602_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7849 *= _6677.y;\n            _7850 *= _6677.z;\n            _7852 *= _6666.w;\n        }\n        if (_602_fa_layers_c.z > 1.5f)\n        {\n            _7853 *= mrt.x;\n            _7855 *= mrt.w;\n        }\n    }\n    Surface _7874 = { _6570.xyz, _6570.w, _7844, clamp(_602_fa_pbr.x * _6638.z, 0.0f, 1.0f), clamp(_602_fa_pbr.y * _6638.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_602_fa_maps.y * (_6677.x - 1.0f)), _602_fa_emissive.xyz + (_602_fa_model_emissive.xyz * _6707), _7849, _7850, _602_fa_layers_b.xyz, _7852, _7853, _602_fa_layers_a.w, _7855, _602_fa_layers_c.y, _602_fa_layers_d.xyz };\n    return _7874;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1771 = rect.zw - rect.xy;\n    float2 _1775 = _1771 * atlas;\n    float2 _1779 = ddx * _1775;\n    float2 _1783 = ddy * _1775;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1771), clamp(0.5f * log2(max(max(dot(_1779, _1779), dot(_1783, _1783)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1816 = _602_fa_counts.y < 0.5f;\n    bool _1823;\n    if (!_1816)\n    {\n        _1823 = _602_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1823 = _1816;\n    }\n    if (_1823)\n    {\n        return;\n    }\n    float3 _1829 = ddx(world_pos);\n    float3 _1832 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1836 = fa_cluster_texel(param);\n    int _1840 = int(_1836.w);\n    if (_1840 < 1)\n    {\n        return;\n    }\n    int _1850 = int(_602_fa_counts.y + 0.5f);\n    int param_1 = _1850;\n    float4 _1854 = fa_light_texel(param_1);\n    float2 _1857 = _1854.yz;\n    int _1861 = int(_1854.w);\n    int param_2 = _1850 + 1;\n    float4 _1866 = fa_light_texel(param_2);\n    float _1867 = _1866.x;\n    int _1873 = int(_602_fa_counts.w + 0.5f) - 1;\n    int _1877 = int(_1836.z);\n    float3 _2142;\n    for (int k = 0; k < _1840; k++)\n    {\n        int _1890 = _1877 + k;\n        int param_3 = _1861 + (_1890 >> 2);\n        int _1907 = (_1850 + 2) + (int(fa_light_texel(param_3)[_1890 & 3]) * 7);\n        int param_4 = _1907 + 6;\n        float4 _1912 = fa_light_texel(param_4);\n        if (((int(_1912.w + 0.5f) >> _1873) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1907;\n        float4 _1927 = fa_light_texel(param_5);\n        int param_6 = _1907 + 1;\n        float4 _1932 = fa_light_texel(param_6);\n        int param_7 = _1907 + 2;\n        float4 _1937 = fa_light_texel(param_7);\n        float3 _1940 = _1927.xyz;\n        float _1945 = dot(_1940, world_pos) + _1927.w;\n        float3 _1947 = _1932.xyz;\n        float _1952 = dot(_1947, world_pos) + _1932.w;\n        float3 _1954 = _1937.xyz;\n        float _1959 = dot(_1954, world_pos) + _1937.w;\n        bool _1964 = abs(_1945) > 0.5f;\n        bool _1972;\n        if (!_1964)\n        {\n            _1972 = abs(_1952) > 0.5f;\n        }\n        else\n        {\n            _1972 = _1964;\n        }\n        bool _1980;\n        if (!_1972)\n        {\n            _1980 = abs(_1959) > 0.5f;\n        }\n        else\n        {\n            _1980 = _1972;\n        }\n        if (_1980)\n        {\n            continue;\n        }\n        float _1995 = clamp(dot(geo_normal, normalize(_1954)) * _1912.z, 0.0f, 1.0f);\n        if (_1995 <= 0.0f)\n        {\n            continue;\n        }\n        float _2015 = (clamp((0.5f - abs(_1959)) * 10.0f, 0.0f, 1.0f) * _1995) * _1912.x;\n        float2 _2023 = float2(_1945 + 0.5f, 0.5f - _1952);\n        float2 _2033 = float2(dot(_1940, _1829), dot(_1947, _1829));\n        float2 _2043 = float2(dot(_1940, _1832), dot(_1947, _1832));\n        int param_8 = _1907 + 5;\n        float4 _2048 = fa_light_texel(param_8);\n        int param_9 = _1907 + 3;\n        float4 _2053 = fa_light_texel(param_9);\n        int param_10 = _1907 + 4;\n        float4 _2058 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2048.xyz;\n        bool _2068 = _2053.z > _2053.x;\n        if (_2068)\n        {\n            float4 param_11 = _2053;\n            float2 param_12 = _2023;\n            float2 param_13 = _1857;\n            float2 param_14 = _2033;\n            float2 param_15 = _2043;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1867 > 0.5f) && (_1867 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2094 = fa_dc_to_linear(param_16);\n                float4 _7924 = tx;\n                _7924.x = _2094.x;\n                _7924.y = _2094.y;\n                _7924.z = _2094.z;\n                tx = _7924;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2015 * tex_a) * _2048.w, 0.0f, 1.0f).xxx);\n        if (_2058.z > _2058.x)\n        {\n            float4 param_17 = _2058;\n            float2 param_18 = _2023;\n            float2 param_19 = _1857;\n            float2 param_20 = _2033;\n            float2 param_21 = _2043;\n            float4 _2138 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1867 > 1.5f)\n            {\n                float3 param_22 = _2138.xyz;\n                float3 _2148 = fa_dc_to_srgb(param_22);\n                _2142 = _2148;\n            }\n            else\n            {\n                _2142 = _2138.xyz;\n            }\n            float3 _2157 = (_2142 * 2.0f) - 1.0f.xxx;\n            float2 _2162 = _2157.xy * _1912.y;\n            float3 _2184 = (normalize(_1940) * _2162.x) + (normalize(_1947) * _2162.y);\n            float3 _2187 = normalize(normal);\n            normal = normalize(lerp(_2187, normalize((_2187 * max(_2157.z, 0.0500000007450580596923828125f)) + (_2184 - (_2187 * dot(_2187, _2184)))), clamp(_2015 * (_2068 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4211 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4218 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4221 = int(_4211);\n    int _4224 = int(_4218);\n    float _4234 = _4218 - float(_4224);\n    int _4289 = (_4221 * 9) + _4224;\n    int _4309 = ((_4221 + 1) * 9) + _4224;\n    return lerp(lerp(_4285[_4289], _4285[_4289 + 1], _4234), lerp(_4285[_4309], _4285[_4309 + 1], _4234), _4211 - float(_4221));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7767 = false;\n    float _7768 = 1.0f;\n    float _7769 = 1.0f;\n    float _7770 = 1.0f;\n    float _7771 = 0.0f;\n    float _7772 = 0.0f;\n    float _7773 = 0.0f;\n    float _7774 = 0.0f;\n    float _7776 = 1.0f;\n    bool _7777 = false;\n    float3 _7778 = 0.0f.xxx;\n    float _7779 = 1.0f;\n    float _7780 = 1.0f;\n    float _7781 = 1.0f;\n    float _7782 = 0.0f;\n    float _7783 = 0.0f;\n    float3 _7784 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7785 = float3(0.0f, 0.0f, 1.0f);\n    float _7786 = 1.0f;\n    float _7787 = 1.0f;\n    float _4360 = clamp(s.specular, 0.0f, 1.0f);\n    float _4364 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4369 = (_4360 != 1.0f) || (_4364 != 1.5f);\n    bool _4378;\n    if (!_4369)\n    {\n        _4378 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4378 = _4369;\n    }\n    if (_4378)\n    {\n        float _4386 = (_4364 - 1.0f) / (_4364 + 1.0f);\n        f0 = lerp(min((_4386 * _4386).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4360, s.albedo, metallic.xxx);\n        _7768 = lerp(_4360, 1.0f, metallic);\n        _7767 = true;\n    }\n    float _4413 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4413 > 0.0f)\n    {\n        float _4421 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7771 = _4413;\n        _7772 = _4421;\n        float _4428 = _4421 * _4421;\n        _7773 = _4428;\n        _7774 = _4428 * _4428;\n        float _4440 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7776 = _4440;\n        _7769 = 1.0f - (_4413 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4440, 0.0f, 1.0f), 5.0f))));\n        _7767 = true;\n    }\n    float3 _4459 = max(s.sheen_color, 0.0f.xxx);\n    float _4468 = max(_4459.x, max(_4459.y, _4459.z));\n    if (_4468 > 0.0f)\n    {\n        float _4476 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7777 = true;\n        _7778 = _4459;\n        _7779 = _4476;\n        _7780 = _4476 * _4476;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4476;\n        float _4493 = fa_sheen_albedo(param, param_1);\n        _7782 = _4493;\n        _7781 = 1.0f - min(_4468 * _4493, 1.0f);\n        _7767 = true;\n    }\n    _7770 = _7769 * _7781;\n    float _4512 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4512 != 0.0f)\n    {\n        float3 _4527 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4527;\n        if (dot(_4527, _4527) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4539 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4539.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4539.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4539.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4543 = t;\n        float3 _4544 = normalize(_4543);\n        t = _4544;\n        float3 _4569 = normalize((_4544 * cos(s.anisotropy_rotation)) + ((cross(n, _4544) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7784 = _4569;\n        _7785 = cross(n, _4569);\n        float _4579 = roughness * roughness;\n        float _4585 = lerp(_4579, 1.0f, _4512 * _4512);\n        bool _4587 = _4512 > 0.0f;\n        _7786 = _4587 ? _4585 : _4579;\n        _7787 = _4587 ? _4579 : _4585;\n        _7783 = _4512;\n        _7767 = true;\n    }\n    FaLayers _7809 = { _7767, _7768, _7769, _7770, _7771, _7772, _7773, _7774, i.world_normal, _7776, _7777, _7778, _7779, _7780, _7781, _7782, _7783, _7784, _7785, _7786, _7787 };\n    return _7809;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3441_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3441_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_602_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3382 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3382;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3992 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3997 = _602_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3992 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3997)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _602_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3992;\n            }\n        }\n        else\n        {\n            amb = _602_fa_ambient.xyz * _3992;\n        }\n    }\n    bool _4048 = _602_fa_rpa_tile.w > 0.0f;\n    if (_4048)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _602_fa_rpa_tile.xy;\n            float param_4 = _602_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _602_fa_rpa_tile.w);\n        }\n    }\n    bool _4079 = _602_fa_rpb_tile.w > 0.0f;\n    if (_4079)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _602_fa_rpb_tile.xy;\n            float param_7 = _602_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _602_fa_rpb_tile.w);\n        }\n    }\n    if ((_3997 || _4048) || _4079)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_602_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _602_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_602_fa_cl_info.x) + int(_602_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_602_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5353;\n    if (fa_lm.z > 0.5f)\n    {\n        _5353 = 0.0f;\n    }\n    else\n    {\n        _5353 = 1.0f - clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5364 = _5353 < 1.0f;\n    bool _5370;\n    if (_5364)\n    {\n        int param = li;\n        _5370 = fa_light_baked(param);\n    }\n    else\n    {\n        _5370 = _5364;\n    }\n    return _5370 ? _5353 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _670_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _670_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _789 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _802 = (c - (ru * hx)) - p;\n        float3 _808 = ru * (2.0f * hx);\n        float _814 = max(dot(_808, _808), 9.9999999392252902907785028219223e-09f);\n        float _818 = dot(_802, _808);\n        float t = clamp((-_818) / _814, 0.0f, 1.0f);\n        if (_789)\n        {\n            float _833 = dot(r, _808);\n            float _839 = _814 - (_833 * _833);\n            if (abs(_839) > (9.9999997473787516355514526367188e-06f * _814))\n            {\n                t = clamp(((dot(r, _802) * _833) - _818) / _839, 0.0f, 1.0f);\n            }\n        }\n        return (p + _802) + (_808 * t);\n    }\n    float3 q = p;\n    float _871 = dot(r, axis);\n    bool _879;\n    if (_789)\n    {\n        _879 = abs(_871) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _879 = _789;\n    }\n    if (_879)\n    {\n        float _889 = dot(c - p, axis) / _871;\n        if (_889 > 0.0f)\n        {\n            q = p + (r * _889);\n        }\n    }\n    float3 _902 = q - c;\n    float2 xy = float2(dot(_902, ru), dot(_902, uu));\n    if (shape > 0.5f)\n    {\n        float _917 = length(xy);\n        if (_917 > hx)\n        {\n            xy *= (hx / _917);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _550 = abs(d);\n    float _552 = _550.x;\n    float _554 = _550.y;\n    bool _555 = _552 >= _554;\n    bool _563;\n    if (_555)\n    {\n        _563 = _552 >= _550.z;\n    }\n    else\n    {\n        _563 = _555;\n    }\n    int _564;\n    if (_563)\n    {\n        _564 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _579;\n        if (_554 >= _550.z)\n        {\n            _579 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _579 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _564 = _579;\n    }\n    return _564;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _709 = dot(d, right);\n    float _713 = dot(d, up);\n    float _724;\n    if (((_709 * _709) + (_713 * _713)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _724 = atan2(_713, _709) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _724 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_724 - floor(_724)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _955 = fa_light_base(param);\n    bool _959 = _602_fa_ambient.w > 4.5f;\n    int param_1 = _955;\n    float4 _963 = fa_light_texel(param_1);\n    int param_2 = _955 + 1;\n    float4 _968 = fa_light_texel(param_2);\n    float _971 = _968.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _983 = _959 && (_971 > 2.5f);\n    fa_light_is_area = _983;\n    bool _985 = _971 < 0.5f;\n    float3 l;\n    if (_985)\n    {\n        l = normalize(_963.xyz);\n        if (_959)\n        {\n            int param_3 = _955 + 6;\n            float4 _999 = fa_light_texel(param_3);\n            if (_999.z > 0.5f)\n            {\n                int param_4 = _955 + 4;\n                float4 _1009 = fa_light_texel(param_4);\n                int param_5 = _955 + 5;\n                float4 _1014 = fa_light_texel(param_5);\n                float2 param_6 = _999.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1009.xyz) * _1009.w, (-dot(world_pos, _1014.xyz)) * _1014.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1044 = _963.xyz;\n        float3 _1046 = _1044 - world_pos;\n        float3 to_light = _1046;\n        float _1049 = length(_1046);\n        float reach = _1049;\n        bool front = true;\n        if (_983)\n        {\n            int param_8 = _955 + 7;\n            reach = max(_1049 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _955 + 4;\n            float4 _1073 = fa_light_texel(param_9);\n            int param_10 = _955 + 5;\n            float4 _1078 = fa_light_texel(param_10);\n            int param_11 = _955 + 6;\n            float4 _1083 = fa_light_texel(param_11);\n            float _1084 = _1083.w;\n            int param_12 = _955 + 2;\n            float3 _1091 = normalize(fa_light_texel(param_12).xyz);\n            bool _1093 = _1084 > 1.5f;\n            bool _1101;\n            if (!_1093)\n            {\n                _1101 = dot(_1091, to_light) < 0.0f;\n            }\n            else\n            {\n                _1101 = _1093;\n            }\n            front = _1101;\n            float3 r = 0.0f.xxx;\n            float3 _1110 = _602_fa_camera_pos.xyz - world_pos;\n            bool _1114 = dot(n, n) > 0.5f;\n            bool _1122;\n            if (_1114)\n            {\n                _1122 = dot(_1110, _1110) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1122 = _1114;\n            }\n            if (_1122)\n            {\n                r = reflect(-normalize(_1110), normalize(n));\n            }\n            float3 param_13 = _1044;\n            float3 param_14 = _1091;\n            float3 param_15 = _1073.xyz;\n            float3 param_16 = _1078.xyz;\n            float param_17 = _1073.w;\n            float param_18 = _1078.w;\n            float param_19 = _1084;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1158 = length(to_light);\n        dist = _1158;\n        l = to_light / max(_1158, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1172 = reach / max(_963.w, 0.001000000047497451305389404296875f);\n        float _1178 = clamp(1.0f - (_1172 * _1172), 0.0f, 1.0f);\n        float _1180;\n        if (front)\n        {\n            _1180 = _1178 * _1178;\n        }\n        else\n        {\n            _1180 = 0.0f;\n        }\n        atten = _1180;\n        bool _1191 = _971 < 2.5f;\n        if ((_971 > 1.5f) && _1191)\n        {\n            int param_22 = _955 + 2;\n            float4 _1199 = fa_light_texel(param_22);\n            float _1209 = _1199.w;\n            int param_23 = _955 + 3;\n            float4 _1214 = fa_light_texel(param_23);\n            float _1215 = _1214.x;\n            float cos_inner = _1215;\n            if (_1215 > 1.5f)\n            {\n                cos_inner = lerp(_1209, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1209, cos_inner, dot(-l, normalize(_1199.xyz)));\n        }\n        if (_959 && (_971 < 1.5f))\n        {\n            int param_24 = _955 + 6;\n            float4 _1239 = fa_light_texel(param_24);\n            if (_1239.z > 0.5f)\n            {\n                float3 _1247 = -to_light;\n                int param_25 = _955 + 4;\n                int param_26 = _955 + 5;\n                float3 _1261 = fa_light_texel(param_25).xyz;\n                float3 _1265 = fa_light_texel(param_26).xyz;\n                float3 _1274 = float3(dot(_1247, _1261), dot(_1247, _1265), dot(_1247, cross(_1261, _1265)));\n                float3 param_27 = _1274;\n                int _1278 = fa_cube_face(param_27);\n                int param_28 = _1278;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1305 = float2(dot(_1274, cross(param_29, param_30)), dot(_1274, param_30)) / max(dot(_1274, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1309 = _1278 / 3;\n                float2 param_31 = _1239.xy + (float2(float(_1278 - (_1309 * 3)), float(_1309)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1305.x), 0.5f - (0.5f * _1305.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _955 + 7;\n            float4 _1339 = fa_light_texel(param_33);\n            if (_1339.z > 0.5f)\n            {\n                int param_34 = _955 + 2;\n                int param_35 = _955 + 4;\n                int param_36 = _955 + 5;\n                float2 param_37 = _1339.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_959 && _1191)\n            {\n                int param_42 = _955 + 6;\n                float4 _1386 = fa_light_texel(param_42);\n                int param_43 = _955 + 7;\n                float4 _1391 = fa_light_texel(param_43);\n                bool _1394 = _1386.z > 0.5f;\n                bool _1401;\n                if (!_1394)\n                {\n                    _1401 = _1391.z > 0.5f;\n                }\n                else\n                {\n                    _1401 = _1394;\n                }\n                if (_1401)\n                {\n                    int param_44 = _955 + 2;\n                    float4 _1408 = fa_light_texel(param_44);\n                    float3 _1412 = normalize(_1408.xyz);\n                    int param_45 = _955 + 4;\n                    float4 _1417 = fa_light_texel(param_45);\n                    int param_46 = _955 + 5;\n                    float4 _1422 = fa_light_texel(param_46);\n                    if (_1394)\n                    {\n                        float3 _1430 = -to_light;\n                        float _1437 = _1408.w;\n                        float _1453 = 0.5f / max(dot(_1430, _1412) * (sqrt(max(1.0f - (_1437 * _1437), 0.0f)) / max(_1437, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1386.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1430, _1417.xyz) * _1453), 0.5f - (dot(_1430, _1422.xyz) * _1453));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1391.z > 0.5f)\n                    {\n                        float2 param_49 = _1391.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1412;\n                        float3 param_52 = _1417.xyz;\n                        float3 param_53 = _1422.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7755 = _968.xyz * atten;\n    if (_959)\n    {\n        _7755 *= fa_light_tint;\n    }\n    int _1522;\n    if (_985)\n    {\n        _1522 = 0;\n    }\n    else\n    {\n        _1522 = ((_971 > 1.5f) && (_971 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7766 = { l, _7755, atten, 1.0f, dist, _1522 };\n    return _7766;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2259;\n    if (i == 0)\n    {\n        _2259 = _2269_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2275;\n        if (i == 1)\n        {\n            _2275 = _2269_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2283;\n            if (i == 2)\n            {\n                _2283 = _2269_fa_shadow_split.z;\n            }\n            else\n            {\n                _2283 = _2269_fa_shadow_split.w;\n            }\n            _2275 = _2283;\n        }\n        _2259 = _2275;\n    }\n    return _2259;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2316 = fa_shadow_depth(param, param_1);\n    float _2320;\n    if (conv.x < 0.5f)\n    {\n        _2320 = _2316;\n    }\n    else\n    {\n        _2320 = (conv.y * conv.z) / (conv.z - (_2316 * (conv.z - conv.y)));\n    }\n    return _2320;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2247 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2247), sin(_2247)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2366 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2375;\n        if (k < 0.0f)\n        {\n            _2375 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2375 = k;\n        }\n        float _2395 = clamp((_2375 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2366;\n            float2 _2414 = fa_shadow_vogel(param_3, param_4, param_5) * _2395;\n            float2 param_6 = uv + (_2414 * _2269_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2426 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2426 < (zr - (length(_2414) * plane)))\n            {\n                sum += _2426;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2452 = sum / cnt;\n        float _2462;\n        if (k < 0.0f)\n        {\n            _2462 = (-k) / max(_2452, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2462 = k;\n        }\n        radius = clamp(((max(zr - _2452, 0.0f) * unit) * _2462) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2484 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2484; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2484;\n        float param_11 = _2366;\n        float2 _2503 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2503 * _2269_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2503) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2484);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2545 = max(_2269_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2550 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2556 = sqrt(1.0f - (_2550 * _2550));\n    float _2563 = min(_2556 / max(_2550, 0.20000000298023223876953125f), 4.0f);\n    float _2568;\n    if (_2269_fa_shadow_bias.y > 0.0f)\n    {\n        _2568 = _2269_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2568 = 1.5f * _2269_fa_shadow_info[ci].x;\n    }\n    float4 _2593 = mul(float4(world + (n * (_2568 * _2556)), 1.0f), _2269_fa_shadow_mat[ci]);\n    float _2600 = _2593.x;\n    bool _2603 = _2600 < _2269_fa_shadow_rect[ci].x;\n    bool _2612;\n    if (!_2603)\n    {\n        _2612 = _2600 > _2269_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2612 = _2603;\n    }\n    bool _2621;\n    if (!_2612)\n    {\n        _2621 = _2593.y < _2269_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2621 = _2612;\n    }\n    bool _2630;\n    if (!_2621)\n    {\n        _2630 = _2593.y > _2269_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2630 = _2621;\n    }\n    bool _2637;\n    if (!_2630)\n    {\n        _2637 = _2593.z > 1.0f;\n    }\n    else\n    {\n        _2637 = _2630;\n    }\n    if (_2637)\n    {\n        return -1.0f;\n    }\n    float _2645;\n    if (_2269_fa_shadow_bias.x > 0.0f)\n    {\n        _2645 = _2269_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2645 = 1.5f * _2269_fa_shadow_info[ci].x;\n    }\n    float2 param = _2593.xy;\n    float4 param_1 = _2269_fa_shadow_rect[ci];\n    float param_2 = _2593.z - ((_2645 * (1.0f + (0.5f * _2563))) / _2545);\n    float param_3 = _2269_fa_shadow_info[ci].x;\n    float param_4 = _2545;\n    float param_5 = _2545 * 0.25f;\n    float param_6 = ((_2269_fa_shadow_info[ci].x * min(_2563, 3.0f)) * 0.5f) / _2545;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2269_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2269_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_602_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3023 = int(_2269_fa_shadow_cfg.x + 0.5f);\n    if (_3023 < 1)\n    {\n        return 1.0f;\n    }\n    float _3038 = dot(world - _2269_fa_shadow_eye.xyz, _2269_fa_shadow_fwd.xyz);\n    int param = _3023 - 1;\n    if (_3038 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3050 = _3023 > 1;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3038 > _2269_fa_shadow_split.x;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 1;\n    }\n    bool _3061 = _3023 > 2;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3038 > _2269_fa_shadow_split.y;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 2;\n    }\n    bool _3072 = _3023 > 3;\n    bool _3079;\n    if (_3072)\n    {\n        _3079 = _3038 > _2269_fa_shadow_split.z;\n    }\n    else\n    {\n        _3079 = _3072;\n    }\n    if (_3079)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3023)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3105 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3105;\n        if (_3105 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2269_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3130;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3130 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3130 = _2269_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3149 = _2269_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3130, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3160 = clamp((_3038 - (fa_shadow_split_at(param_7) - _3149)) / _3149, 0.0f, 1.0f);\n        if (_3160 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3023)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3181 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3181;\n                if (_3181 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3160);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2703 = _602_fa_pbr.z < 0.5f;\n    bool _2710;\n    if (!_2703)\n    {\n        _2710 = _2269_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2710 = _2703;\n    }\n    if (_2710)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2269_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2723 = fa_light_texel(param);\n    float _2724 = _2723.x;\n    if (_2724 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2733 = int(_2724 + 0.5f);\n    int param_1 = _2733;\n    float4 _2737 = fa_light_texel(param_1);\n    int param_2 = _2733 + 1;\n    float4 _2742 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2745 = _2737.y;\n    if (_2745 > 0.0f)\n    {\n        float _2762 = 1.0f - smoothstep(0.75f * _2745, _2745, length(world - _2269_fa_shadow_eye.xyz));\n        fade = _2762;\n        if (_2762 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2737.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2786 = (_2733 + 2) + (face * 6);\n    int param_4 = _2786;\n    int param_5 = _2786 + 1;\n    int param_6 = _2786 + 3;\n    float4 _2800 = fa_light_texel(param_6);\n    int param_7 = _2786 + 4;\n    float4 _2805 = fa_light_texel(param_7);\n    int param_8 = _2786 + 5;\n    float4 _2810 = fa_light_texel(param_8);\n    float _2822 = _2810.x * max(dot(_2800, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2827 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2850 = clamp(dot(n, _2800.xyz), -1.0f, 1.0f);\n    float _2869 = min(sqrt(1.0f - (_2850 * _2850)) / max(abs(dot(n, world - lpos)) / max(dot(_2800, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2872 = _2742.y;\n    float _2874;\n    if (_2872 > 0.0f)\n    {\n        _2874 = _2872;\n    }\n    else\n    {\n        _2874 = 1.5f * _2822;\n    }\n    float4 _2894 = float4(world + (n * (_2874 * sqrt(1.0f - (_2827 * _2827)))), 1.0f);\n    float _2898 = dot(_2800, _2894);\n    float _2901 = _2810.y;\n    if (_2898 < _2901)\n    {\n        return 1.0f;\n    }\n    float2 _2916 = float2(dot(fa_light_texel(param_4), _2894), dot(fa_light_texel(param_5), _2894)) / _2898.xx;\n    float _2918 = _2916.x;\n    bool _2921 = _2918 < _2805.x;\n    bool _2930;\n    if (!_2921)\n    {\n        _2930 = _2918 > _2805.z;\n    }\n    else\n    {\n        _2930 = _2921;\n    }\n    bool _2939;\n    if (!_2930)\n    {\n        _2939 = _2916.y < _2805.y;\n    }\n    else\n    {\n        _2939 = _2930;\n    }\n    bool _2948;\n    if (!_2939)\n    {\n        _2948 = _2916.y > _2805.w;\n    }\n    else\n    {\n        _2948 = _2939;\n    }\n    if (_2948)\n    {\n        return 1.0f;\n    }\n    float _2954 = _2742.x;\n    float _2956;\n    if (_2954 > 0.0f)\n    {\n        _2956 = _2954;\n    }\n    else\n    {\n        _2956 = 1.5f * _2822;\n    }\n    float2 param_9 = _2916;\n    float4 param_10 = _2805;\n    float param_11 = _2898 - (_2956 * (1.0f + (0.5f * _2869)));\n    float param_12 = _2822;\n    float param_13 = 1.0f;\n    float param_14 = _2810.z * 0.25f;\n    float param_15 = (_2822 * min(_2869, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2901, _2810.z);\n    int param_17 = int(_2737.z + 0.5f);\n    float param_18 = _2737.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5097 = _602_fa_ct_a.x < 0.5f;\n    bool _5104;\n    if (!_5097)\n    {\n        _5104 = _2269_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5104 = _5097;\n    }\n    if (_5104)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2269_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5117 = fa_light_texel(param);\n    float _5118 = _5117.y;\n    float len = _5118;\n    if (_5118 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5130 = length(world - _602_fa_camera_pos.xyz);\n    float _5140 = 1.0f - smoothstep(0.5f * _602_fa_ct_b.x, _602_fa_ct_b.x, _5130);\n    if (_5140 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5146 = len;\n    float _5149 = min(_5146, 0.89999997615814208984375f * dist);\n    len = _5149;\n    float _5154 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5130);\n    float _5159 = _5154 + (0.5f * _5149);\n    float3 _5165 = world + (gn * _5154);\n    float _5167 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5231;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5182 = (float(k) + _5167) * 0.083333335816860198974609375f;\n        float3 _5190 = _5165 + (l * (_5182 * len));\n        float4 _5196 = float4(_5190, 1.0f);\n        float _5202 = dot(_602_fa_ct_vpw, _5196);\n        if (_5202 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5222 = float2(dot(_602_fa_ct_vpx, _5196), dot(_602_fa_ct_vpy, _5196)) / _5202.xx;\n        float _5226 = _5222.x * 0.5f;\n        float _5227 = _5226 + 0.5f;\n        if (_602_fa_ct_a.y > 0.5f)\n        {\n            _5231 = (_5222.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5231 = 0.5f - (_5222.y * 0.5f);\n        }\n        bool _5247 = _5227 < 0.0f;\n        bool _5254;\n        if (!_5247)\n        {\n            _5254 = _5227 >= 1.0f;\n        }\n        else\n        {\n            _5254 = _5247;\n        }\n        bool _5261;\n        if (!_5254)\n        {\n            _5261 = _5231 < 0.0f;\n        }\n        else\n        {\n            _5261 = _5254;\n        }\n        bool _5268;\n        if (!_5261)\n        {\n            _5268 = _5231 >= 1.0f;\n        }\n        else\n        {\n            _5268 = _5261;\n        }\n        if (_5268)\n        {\n            break;\n        }\n        float4 _5287 = fa_screen_tex.Load(int3(int2(float2(_5227, _5231) * _602_fa_ct_a.zw), 0));\n        if (_5287.w < 0.5f)\n        {\n            continue;\n        }\n        float _5306 = (dot(_602_fa_ct_fwd.xyz, _5190) + _602_fa_ct_fwd.w) - _5287.x;\n        if ((_5306 > _5154) && (_5306 < _5159))\n        {\n            occ = max(occ, (1.0f - (_5182 * _5182)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5227, 0.5f - _5226), min(_5231, 1.0f - _5231))));\n        }\n    }\n    return 1.0f - (occ * _5140);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5409 = fa_baked_keep(param);\n    if (_5409 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7822 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7822;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5435 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7824 = _5435.color;\n    float _7825 = _5435.attenuation;\n    float _7826 = _5435.shadow;\n    bool _5438 = _5435.type == 0;\n    if (_5438 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5435.direction;\n        float _5449 = fa_shadow_factor(param_5, param_6);\n        _7826 = _5449;\n        _7824 *= _5449;\n    }\n    else\n    {\n        bool _5460 = _5435.type != 0;\n        bool _5466;\n        if (_5460)\n        {\n            _5466 = _7825 > 0.0f;\n        }\n        else\n        {\n            _5466 = _5460;\n        }\n        if (_5466)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5435.direction;\n            float _5485 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7826 = _5485;\n            _7824 *= _5485;\n        }\n    }\n    bool _5495 = _602_fa_ct_a.x > 0.5f;\n    bool _5501;\n    if (_5495)\n    {\n        _5501 = _7825 > 0.0f;\n    }\n    else\n    {\n        _5501 = _5495;\n    }\n    if (_5501)\n    {\n        float _5508;\n        if (_5438)\n        {\n            _5508 = 1000000000.0f;\n        }\n        else\n        {\n            _5508 = _5435._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5435.direction;\n        float param_18 = _5508;\n        float _5526 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7826 *= _5526;\n        _7824 *= _5526;\n    }\n    float _5539 = _7825;\n    float _5540 = _5539 * _5409;\n    _7825 = _5540;\n    float3 _5544 = _7824;\n    float3 _5545 = _5544 * _5409;\n    _7824 = _5545;\n    LightSample _7841 = { _5435.direction, _5545, _5540, _7826, _5435._distance, _5435.type };\n    return _7841;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5579 = v - (n * dot(v, n));\n    float3 t = _5579;\n    float _5583 = dot(_5579, _5579);\n    float l2 = _5583;\n    if (_5583 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5593;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5593 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5593 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5593;\n        l2 = dot(_5593, _5593);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5628 = dot(a, a);\n    float _5632 = dot(b, b);\n    if ((_5628 < 1.0000000195414813782625560981111e-24f) || (_5632 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5646 = a * rsqrt(_5628);\n    float3 _5651 = b * rsqrt(_5632);\n    float _5655 = dot(_5646, _5651);\n    float _5658 = abs(_5655);\n    float g = (((((((((((0.0416471660137176513671875f * _5658) - 0.1924748718738555908203125f) * _5658) + 0.4179156124591827392578125f) * _5658) - 0.616057217121124267578125f) * _5658) + 0.777722418308258056640625f) * _5658) - 0.999542415142059326171875f) * _5658) + 1.570791721343994140625f;\n    if (_5655 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5655 * _5655), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5646, _5651) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5715 = a.z > 0.0f;\n    bool _5719 = b.z > 0.0f;\n    if (_5715 && _5719)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5715 != _5719)\n        {\n            float3 _5754 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5754.z = 0.0f;\n            if (_5715)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5754;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5754;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5754;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5754;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5803 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5829 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5855 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5881 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5803;\n    float3 param_1 = _5829;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5829;\n    float3 param_7 = _5855;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5855;\n    float3 param_13 = _5881;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5881;\n    float3 param_19 = _5803;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6031 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6055 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6071 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6031;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6055;\n    float4 param_9 = m;\n    float3 param_10 = _6031;\n    float3 param_11 = _6055;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6071;\n    float4 param_14 = m;\n    float3 param_15 = _6031;\n    float3 param_16 = _6071;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6129 = fa_light_base(param);\n    int param_1 = _6129;\n    int param_2 = _6129 + 1;\n    int param_3 = _6129 + 2;\n    int param_4 = _6129 + 4;\n    float4 _6151 = fa_light_texel(param_4);\n    int param_5 = _6129 + 5;\n    float4 _6156 = fa_light_texel(param_5);\n    int param_6 = _6129 + 6;\n    float4 _6161 = fa_light_texel(param_6);\n    float _6162 = _6161.w;\n    float3 _6167 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6169 = _6162 < 1.5f;\n    bool _6176;\n    if (_6169)\n    {\n        _6176 = dot(normalize(fa_light_texel(param_3).xyz), _6167) >= 0.0f;\n    }\n    else\n    {\n        _6176 = _6169;\n    }\n    if (_6176)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6185 = (_6162 > 0.5f) && _6169;\n    float _6189 = _6185 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6192 = _6151.xyz;\n    float _6194 = _6151.w;\n    float3 _6200 = _6156.xyz;\n    float _6202 = _6156.w;\n    float3 up = _6200 * (_6202 * _6189);\n    float _6208;\n    if (_6185)\n    {\n        _6208 = (3.1415927410125732421875f * _6194) * _6194;\n    }\n    else\n    {\n        _6208 = (4.0f * _6194) * _6202;\n    }\n    if (_6162 > 1.5f)\n    {\n        float3 _6234 = cross(_6192, -_6167);\n        float3 perp = _6234;\n        float _6238 = dot(_6234, _6234);\n        float3 _6241;\n        if (_6238 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6241 = perp * rsqrt(_6238);\n        }\n        else\n        {\n            _6241 = _6200;\n        }\n        perp = _6241;\n        up = _6241 * _6202;\n    }\n    float _6262 = max(_6208, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6272 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6272;\n    float3 param_10 = n;\n    float3 param_11 = _6167;\n    float3 _6280 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6272;\n    float3 param_13 = n;\n    float3 param_14 = _6192 * (_6194 * _6189);\n    float3 _6288 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6272;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6296 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6162;\n    float3 param_20 = _6280;\n    float3 param_21 = _6288;\n    float3 param_22 = _6296;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6315 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6315;\n    float2 param_26 = _6315 + float2(64.0f, 0.0f);\n    float4 _6325 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6162;\n    float3 param_29 = _6280;\n    float3 param_30 = _6288;\n    float3 param_31 = _6296;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6325.x) + ((f90.xxx - f0) * _6325.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6167, _6167)) + _6262) / _6262) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4834 = 1.0f / alpha;\n    return ((2.0f + _4834) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4834)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4869 = max(dot(L.nc, l), 0.0f);\n    float _4875 = max(dot(L.nc, h), 0.0f);\n    float _4884 = ((_4875 * _4875) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4884) * _4884)) * (0.5f / max(lerp((2.0f * _4869) * L.coat_ndv, _4869 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4869)) * _4869;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6393;\n    if (L.sheen_on)\n    {\n        _6393 = L.sheen_scale;\n    }\n    else\n    {\n        _6393 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6393);\n    float3 _6406 = normalize(l + v);\n    int param_10 = li;\n    float3 _6417 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6426 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6406), 0.0f);\n        float param_13 = _6426;\n        float param_14 = ndv;\n        result += ((L.sheen * _6417) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6426)) * _6426) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6406;\n        float param_18 = max(dot(v, _6406), 0.0f);\n        result += (_6417 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4737 = tdh / at;\n    float _4741 = bdh / ab;\n    float _4753 = ((_4737 * _4737) + (_4741 * _4741)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4753) * _4753);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4933 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5012 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5012) * _5012);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4933);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4933));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4143 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4146 = _4143.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4146 * _4146, exp2((-9.27999973297119140625f) * ndv)) * _4146) + _4143.y)) + _4143.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3402 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3405 = _3402.x;\n    float _3407 = _3402.z;\n    float2 e = float2(_3405, _3407);\n    if (_3402.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3407)) * ((_3405 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3405)) * ((_3407 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3454;\n    if (lv == 0)\n    {\n        _3454 = 0.0f;\n    }\n    else\n    {\n        _3454 = res + 2.0f;\n    }\n    float _3464;\n    if (lv == 0)\n    {\n        _3464 = 0.0f;\n    }\n    else\n    {\n        _3464 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3454, _3464)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3509;\n    if (res > 64.5f)\n    {\n        _3509 = 5.0f;\n    }\n    else\n    {\n        _3509 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3524 = clamp(rough, 0.0f, 1.0f) * (_3509 - 1.0f);\n    int _3531 = int(min(floor(_3524), _3509 - 2.0f));\n    float _3536 = _3524 - float(_3531);\n    float3 param = d;\n    float2 _3540 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3531;\n    float2 param_4 = _3540;\n    float3 _3550 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3536 < 0.00200000009499490261077880859375f)\n    {\n        return _3550;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3531 + 1;\n    float2 param_8 = _3540;\n    return lerp(_3550, fa_probe_level(param_5, param_6, param_7, param_8), _3536.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3620 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3627 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3634 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3640 = dot(bx.xyz, d);\n    float _3644 = dot(by.xyz, d);\n    float _3648 = dot(bz.xyz, d);\n    float _3654;\n    if (_3640 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3654 = (1.0f - _3620) / _3640;\n    }\n    else\n    {\n        float _3668;\n        if (_3640 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3668 = ((-1.0f) - _3620) / _3640;\n        }\n        else\n        {\n            _3668 = 1000000015047466219876688855040.0f;\n        }\n        _3654 = _3668;\n    }\n    float tx = _3654;\n    float _3685;\n    if (_3644 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3685 = (1.0f - _3627) / _3644;\n    }\n    else\n    {\n        float _3698;\n        if (_3644 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3698 = ((-1.0f) - _3627) / _3644;\n        }\n        else\n        {\n            _3698 = 1000000015047466219876688855040.0f;\n        }\n        _3685 = _3698;\n    }\n    float ty = _3685;\n    float _3714;\n    if (_3648 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3714 = (1.0f - _3634) / _3648;\n    }\n    else\n    {\n        float _3727;\n        if (_3648 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3727 = ((-1.0f) - _3634) / _3648;\n        }\n        else\n        {\n            _3727 = 1000000015047466219876688855040.0f;\n        }\n        _3714 = _3727;\n    }\n    float _3739 = tx;\n    float _3742 = (_3739 > 0.0f) ? _3739 : 1000000015047466219876688855040.0f;\n    tx = _3742;\n    float _3743 = ty;\n    float _3746 = (_3743 > 0.0f) ? _3743 : 1000000015047466219876688855040.0f;\n    ty = _3746;\n    float _3756 = min(_3742, min(_3746, (_3714 > 0.0f) ? _3714 : 1000000015047466219876688855040.0f));\n    if (_3756 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3772 = (fa_world_pos + (d * _3756)) - posw.xyz;\n    float3 _3777;\n    if (dot(_3772, _3772) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3777 = normalize(_3772);\n    }\n    else\n    {\n        _3777 = d;\n    }\n    return _3777;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3823 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3823 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_602_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _602_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3852 = rough * rough;\n            float _3883 = 0.60000002384185791015625f * _3852;\n            base = lerp(lerp(_602_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_602_fa_env_horizon.xyz, _602_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3852)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3883, 0.0500000007450580596923828125f + _3883, d.y).xxx), ((_602_fa_env_sky.xyz + _602_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3852 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3823;\n    }\n    if (_602_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _602_fa_rpa_tile;\n        float4 param_5 = _602_fa_rpa_pos;\n        float4 param_6 = _602_fa_rpa_bx;\n        float4 param_7 = _602_fa_rpa_by;\n        float4 param_8 = _602_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3942 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3942 * _602_fa_rpa_tile.w);\n    }\n    if (_602_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _602_fa_rpb_tile;\n        float4 param_12 = _602_fa_rpb_pos;\n        float4 param_13 = _602_fa_rpb_bx;\n        float4 param_14 = _602_fa_rpb_by;\n        float4 param_15 = _602_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3974 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3974 * _602_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4620;\n        if (L.aniso >= 0.0f)\n        {\n            _4620 = L.b;\n        }\n        else\n        {\n            _4620 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4620, v), _4620), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4653 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4653.x) + (L.f90.xxx * _4653.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4708 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4708.x) + _4708.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4185 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4185.x) + _4185.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2269_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3205 = int(_2269_fa_shadow_cfg.x + 0.5f);\n    float _3215 = dot(world - _2269_fa_shadow_eye.xyz, _2269_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3220 = _3205 > 0;\n    bool _3229;\n    if (_3220)\n    {\n        int param = _3205 - 1;\n        _3229 = _3215 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3229 = _3220;\n    }\n    if (_3229)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3235 = _3205 > 1;\n        bool _3242;\n        if (_3235)\n        {\n            _3242 = _3215 > _2269_fa_shadow_split.x;\n        }\n        else\n        {\n            _3242 = _3235;\n        }\n        if (_3242)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3248 = _3205 > 2;\n        bool _3255;\n        if (_3248)\n        {\n            _3255 = _3215 > _2269_fa_shadow_split.y;\n        }\n        else\n        {\n            _3255 = _3248;\n        }\n        if (_3255)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3261 = _3205 > 3;\n        bool _3268;\n        if (_3261)\n        {\n            _3268 = _3215 > _2269_fa_shadow_split.z;\n        }\n        else\n        {\n            _3268 = _3261;\n        }\n        if (_3268)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _7524 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7524 = -_7524;\n    }\n    float3 _6884 = normalize(_602_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _7537 = { fa_world_pos, _7524, fa_world_tangent, fa_uv, fa_vertex_color, _6884, gl_FrontFacing };\n    SurfaceInput param_1 = _7537;\n    Surface _6892 = fa_standard_surface(param_1);\n    float3 _7555 = _6892.albedo;\n    float _7556 = _6892.alpha;\n    float3 _7557 = _6892.normal;\n    float _7558 = _6892.metallic;\n    float _7559 = _6892.roughness;\n    float _7560 = _6892.occlusion;\n    float3 _7561 = _6892.emission;\n    float _7562 = _6892.clearcoat;\n    float _7563 = _6892.clearcoat_roughness;\n    float3 _7564 = _6892.sheen_color;\n    float _7565 = _6892.sheen_roughness;\n    float _7566 = _6892.anisotropy;\n    float _7567 = _6892.anisotropy_rotation;\n    float _7568 = _6892.specular;\n    float _7569 = _6892.ior;\n    float3 _7570 = _6892.specular_color;\n    SurfaceInput _7545 = { fa_world_pos, _7524, fa_world_tangent, fa_uv, fa_vertex_color, _6884, gl_FrontFacing };\n    SurfaceInput param_2 = _7545;\n    Surface param_3 = _6892;\n    surface(param_2, param_3);\n    _7555 = param_3.albedo;\n    _7556 = param_3.alpha;\n    _7557 = param_3.normal;\n    _7558 = param_3.metallic;\n    _7559 = param_3.roughness;\n    _7560 = param_3.occlusion;\n    _7561 = param_3.emission;\n    _7562 = param_3.clearcoat;\n    _7563 = param_3.clearcoat_roughness;\n    _7564 = param_3.sheen_color;\n    _7565 = param_3.sheen_roughness;\n    _7566 = param_3.anisotropy;\n    _7567 = param_3.anisotropy_rotation;\n    _7568 = param_3.specular;\n    _7569 = param_3.ior;\n    _7570 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _7524;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7555 = param_6;\n    _7557 = param_7;\n    float3 result;\n    if (_602_fa_emissive.w > 0.5f)\n    {\n        result = _7555;\n    }\n    else\n    {\n        float3 _6931 = normalize(_7557);\n        float _6938 = clamp(_7558, 0.0f, 1.0f);\n        float _6942 = clamp(_7559, 0.0500000007450580596923828125f, 1.0f);\n        float _6946 = _6942 * _6942;\n        float _6950 = _6946 * _6946;\n        float _6955 = max(dot(_6931, _6884), 9.9999997473787516355514526367188e-05f);\n        float3 _6961 = _7555 * (1.0f - _6938);\n        float3 _6968 = lerp(0.039999999105930328369140625f.xxx, _7555, _6938.xxx);\n        float3 f0 = _6968;\n        SurfaceInput _7553 = { fa_world_pos, _7524, fa_world_tangent, fa_uv, fa_vertex_color, _6884, gl_FrontFacing };\n        SurfaceInput param_8 = _7553;\n        Surface _7636 = { _7555, _7556, _7557, _7558, _7559, _7560, _7561, _7562, _7563, _7564, _7565, _7566, _7567, _7568, _7569, _7570 };\n        Surface param_9 = _7636;\n        float3 param_10 = _6931;\n        float3 param_11 = _6884;\n        float param_12 = _6938;\n        float param_13 = _6942;\n        float3 param_14 = _6968;\n        FaLayers _6984 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6931;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6961) * _7560;\n        if (_6984.on)\n        {\n            lit *= _6984.base_scale;\n        }\n        int _7006 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7006; ln++)\n        {\n            int param_16 = ln;\n            int _7019 = fa_cl_light(param_16);\n            int param_17 = _7019;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _7019;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _7524;\n            LightSample _7035 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7043 = max(dot(_6931, _7035.direction), 0.0f);\n            float _7049 = _7035.attenuation * _7035.shadow;\n            float3 _7054 = normalize(_7035.direction + _6884);\n            float _7059 = max(dot(_6931, _7054), 0.0f);\n            float _7064 = max(dot(_6884, _7054), 0.0f);\n            bool _7071;\n            if (fa_light_is_area)\n            {\n                _7071 = !_6984.on;\n            }\n            else\n            {\n                _7071 = fa_light_is_area;\n            }\n            if (_7071)\n            {\n                int param_21 = _7019;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6931;\n                float3 param_24 = _6884;\n                float3 param_25 = _6961;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6942;\n                float param_29 = _6955;\n                float param_30 = _7049;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6984;\n                    int param_32 = _7019;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6931;\n                    float3 param_35 = _6884;\n                    float3 param_36 = _7035.direction;\n                    float3 param_37 = _6961;\n                    float3 param_38 = f0;\n                    float param_39 = _6942;\n                    float param_40 = _6955;\n                    float param_41 = _7049;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6984.on)\n                    {\n                        FaLayers param_42 = _6984;\n                        float3 param_43 = _6961;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6931;\n                        float3 param_46 = _6884;\n                        float3 param_47 = _7035.direction;\n                        float3 param_48 = _7054;\n                        float param_49 = _7043;\n                        float param_50 = _6955;\n                        float param_51 = _7059;\n                        float param_52 = _7064;\n                        float param_53 = _6946;\n                        float param_54 = _6950;\n                        int param_55 = _7019;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7049));\n                    }\n                    else\n                    {\n                        float _7177 = ((_7059 * _7059) * (_6950 - 1.0f)) + 1.0f;\n                        int param_56 = _7019;\n                        lit += (((_6961 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _7064, 5.0f))) * (((_6950 / ((3.1415927410125732421875f * _7177) * _7177)) * (0.5f / max(lerp((2.0f * _7043) * _6955, _7043 + _6955, _6946), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _7043))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7043 * _7049));\n                    }\n                }\n            }\n        }\n        if (_6984.on)\n        {\n            FaLayers param_57 = _6984;\n            float3 param_58 = _6931;\n            float3 param_59 = _6884;\n            float3 param_60 = f0;\n            float param_61 = _6942;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7560);\n        }\n        else\n        {\n            float3 param_62 = _6931;\n            float3 param_63 = _6884;\n            float3 param_64 = f0;\n            float param_65 = _6942;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7560);\n        }\n        result = lit;\n    }\n    float3 _7272 = result;\n    float3 _7273 = _7272 + _7561;\n    result = _7273;\n    float3 param_66 = _7273;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _7282 = _602_fa_fog.w > 0.0f;\n    bool _7289;\n    if (!_7282)\n    {\n        _7289 = _602_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7289 = _7282;\n    }\n    if (_7289)\n    {\n        float3 _7298 = fa_world_pos - _602_fa_camera_pos.xyz;\n        float _7304 = dot(_7298, _602_fa_fog_c.xyz);\n        bool _7308 = _602_fa_fog_c.w > 0.5f;\n        float _7309;\n        if (_7308)\n        {\n            _7309 = _7304;\n        }\n        else\n        {\n            _7309 = length(_7298);\n        }\n        float _7321 = _7309 - _602_fa_fog_b.x;\n        if (_7321 > 0.0f)\n        {\n            float _7330 = _602_fa_fog.w * _7321;\n            float tau = _7330 * _7330;\n            if (_602_fa_fog_b.y > 0.0f)\n            {\n                float _7346;\n                if (_7308)\n                {\n                    _7346 = fa_world_pos.y - (_602_fa_fog_c.y * _7304);\n                }\n                else\n                {\n                    _7346 = _602_fa_camera_pos.y;\n                }\n                float _7367 = lerp(_7346, fa_world_pos.y, clamp(_602_fa_fog_b.x / _7309, 0.0f, 1.0f));\n                float _7371 = fa_world_pos.y - _7367;\n                float _7376 = _7367 - _602_fa_fog_b.z;\n                float _7381 = fa_world_pos.y - _602_fa_fog_b.z;\n                bool _7384 = _7376 <= 0.0f;\n                bool _7385 = !_7384;\n                bool _7391;\n                if (_7385)\n                {\n                    _7391 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7391 = _7384;\n                }\n                float _7392;\n                if (_7391)\n                {\n                    _7392 = _602_fa_fog_b.y;\n                }\n                else\n                {\n                    _7392 = _602_fa_fog_b.y * exp(-min(_602_fa_fog_b.w * _7376, 80.0f));\n                }\n                bool _7419;\n                if (_7385)\n                {\n                    _7419 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7419 = _7384;\n                }\n                float _7420;\n                if (_7419)\n                {\n                    _7420 = _602_fa_fog_b.y * _7376;\n                }\n                else\n                {\n                    _7420 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _7376, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                bool _7445 = _7381 <= 0.0f;\n                bool _7452;\n                if (!_7445)\n                {\n                    _7452 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7452 = _7445;\n                }\n                float _7453;\n                if (_7452)\n                {\n                    _7453 = _602_fa_fog_b.y * _7381;\n                }\n                else\n                {\n                    _7453 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _7381, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                float _7480;\n                if (abs(_7371) < 0.001000000047497451305389404296875f)\n                {\n                    _7480 = _7392;\n                }\n                else\n                {\n                    _7480 = (_7453 - _7420) / _7371;\n                }\n                tau += (_7321 * max(_7480, 0.0f));\n            }\n            result = lerp(result, _602_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _7556);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_602",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2269",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 11
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _50_offset : packoffset(c0);\n    float _50_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _150_fa_view_proj : packoffset(c0);\n    row_major float4x4 _150_fa_light_vp : packoffset(c4);\n    float4 _150_fa_uv_scale : packoffset(c8);\n    float4 _150_fa_time : packoffset(c9);\n    float4 _150_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _197_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_197_fa_joint_rows[_188] * weights[i]);\n        r1 += (_197_fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197_fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _399 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150_fa_uv_scale.xy, color, position };\n    return _399;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _50_offset;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _150_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4285[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _602_fa_camera_pos : packoffset(c0);\n    float4 _602_fa_ambient : packoffset(c1);\n    float4 _602_fa_base_color : packoffset(c2);\n    float4 _602_fa_emissive : packoffset(c3);\n    float4 _602_fa_model_emissive : packoffset(c4);\n    float4 _602_fa_pbr : packoffset(c5);\n    float4 _602_fa_maps : packoffset(c6);\n    float4 _602_fa_fog : packoffset(c7);\n    float4 _602_fa_fog_b : packoffset(c8);\n    float4 _602_fa_fog_c : packoffset(c9);\n    float4 _602_fa_counts : packoffset(c10);\n    float4 _602_fa_env_sky : packoffset(c11);\n    float4 _602_fa_env_horizon : packoffset(c12);\n    float4 _602_fa_time : packoffset(c13);\n    float4 _602_fa_cl_vpx : packoffset(c14);\n    float4 _602_fa_cl_vpy : packoffset(c15);\n    float4 _602_fa_cl_vpw : packoffset(c16);\n    float4 _602_fa_cl_fwd : packoffset(c17);\n    float4 _602_fa_cl_grid : packoffset(c18);\n    float4 _602_fa_cl_info : packoffset(c19);\n    float4 _602_fa_layers_a : packoffset(c20);\n    float4 _602_fa_layers_b : packoffset(c21);\n    float4 _602_fa_layers_c : packoffset(c22);\n    float4 _602_fa_layers_d : packoffset(c23);\n    float4 _602_fa_ct_a : packoffset(c24);\n    float4 _602_fa_ct_b : packoffset(c25);\n    float4 _602_fa_ct_vpx : packoffset(c26);\n    float4 _602_fa_ct_vpy : packoffset(c27);\n    float4 _602_fa_ct_vpw : packoffset(c28);\n    float4 _602_fa_ct_fwd : packoffset(c29);\n    float4 _602_fa_probe_sh[9] : packoffset(c30);\n    float4 _602_fa_atlas : packoffset(c39);\n    float4 _602_fa_rpa_tile : packoffset(c40);\n    float4 _602_fa_rpa_pos : packoffset(c41);\n    float4 _602_fa_rpa_bx : packoffset(c42);\n    float4 _602_fa_rpa_by : packoffset(c43);\n    float4 _602_fa_rpa_bz : packoffset(c44);\n    float4 _602_fa_rpb_tile : packoffset(c45);\n    float4 _602_fa_rpb_pos : packoffset(c46);\n    float4 _602_fa_rpb_bx : packoffset(c47);\n    float4 _602_fa_rpb_by : packoffset(c48);\n    float4 _602_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2269_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2269_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2269_fa_shadow_info[4] : packoffset(c20);\n    float4 _2269_fa_shadow_split : packoffset(c24);\n    float4 _2269_fa_shadow_cfg : packoffset(c25);\n    float4 _2269_fa_shadow_bias : packoffset(c26);\n    float4 _2269_fa_shadow_eye : packoffset(c27);\n    float4 _2269_fa_shadow_fwd : packoffset(c28);\n    float4 _2269_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1540 = _602_fa_cl_info.x < 0.0f;\n    bool _1547;\n    if (!_1540)\n    {\n        _1547 = _602_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1547 = _1540;\n    }\n    bool _1555;\n    if (!_1547)\n    {\n        _1555 = _602_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1555 = _1547;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = _602_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    bool _1569;\n    if (!_1562)\n    {\n        _1569 = _602_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1569 = _1562;\n    }\n    if (_1569)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1579 = float4(world_pos, 1.0f);\n    float _1585 = dot(_602_fa_cl_vpw, _1579);\n    if (!(_1585 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1607 = float2(dot(_602_fa_cl_vpx, _1579), dot(_602_fa_cl_vpy, _1579)) / _1585.xx;\n    int _1611 = int(_602_fa_cl_grid.x);\n    int _1615 = int(_602_fa_cl_grid.y);\n    int param = (int(_602_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_602_fa_cl_fwd.xyz, world_pos) + _602_fa_cl_fwd.w, _602_fa_cl_grid.w) / _602_fa_cl_grid.w) * _602_fa_cl_grid.z)), 0, int(_602_fa_cl_info.y) - 1) * _1615) + clamp(int(floor(((_1607.y * 0.5f) + 0.5f) * _602_fa_cl_grid.y)), 0, _1615 - 1)) * _1611)) + clamp(int(floor(((_1607.x * 0.5f) + 0.5f) * _602_fa_cl_grid.x)), 0, _1611 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1691 = fa_cluster_texel(param);\n    return int2(int(_1691.x), int(_1691.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_602_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5383 = fa_cluster_lookup(param);\n    fa_cl_slot = _5383.x;\n    fa_cl_local = _5383.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6517 = fa_linear_to_srgb(param);\n        c = _6517;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6525 = fa_srgb_to_linear(param_1);\n            c = _6525;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _484;\n    if (i.front_facing)\n    {\n        _484 = i.world_normal;\n    }\n    else\n    {\n        _484 = -i.world_normal;\n    }\n    float3 _508 = normalize(i.world_tangent.xyz - (_484 * dot(_484, i.world_tangent.xyz)));\n    float3 _535 = normalize(((_508 * m.x) + ((cross(_484, _508) * i.world_tangent.w) * m.y)) + (_484 * m.z));\n    float3 _538;\n    if (i.front_facing)\n    {\n        _538 = _535;\n    }\n    else\n    {\n        _538 = -_535;\n    }\n    return _538;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _602_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6556 = fa_tex_fix(param_2, param_3);\n    float4 _8044 = base_t;\n    _8044.x = _6556.x;\n    _8044.y = _6556.y;\n    _8044.z = _6556.z;\n    base_t = _8044;\n    float4 _6570 = (_8044 * _602_fa_base_color) * i.vertex_color;\n    float3 _7844 = i.world_normal;\n    if (_602_fa_maps.z > 0.5f)\n    {\n        float param_4 = _602_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6602 = fa_tex_fix(param_6, param_7);\n        float3 _6605 = (_6602 * 2.0f) - 1.0f.xxx;\n        float2 _6610 = _6605.xy * _602_fa_maps.x;\n        float3 _8052 = _6605;\n        _8052.x = _6610.x;\n        _8052.y = _6610.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _8052;\n        _7844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _602_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6638 = fa_tex_fix(param_12, param_13);\n    float4 _8055 = mrt;\n    _8055.x = _6638.x;\n    _8055.y = _6638.y;\n    _8055.z = _6638.z;\n    mrt = _8055;\n    float4 _6666 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _602_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6666.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6677 = fa_tex_fix(param_16, param_17);\n    float param_18 = _602_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6707 = fa_tex_fix(param_20, param_21);\n    float _7849 = _602_fa_layers_a.x;\n    float _7850 = _602_fa_layers_a.y;\n    float _7853 = _602_fa_layers_a.z;\n    float _7852 = _602_fa_layers_b.w;\n    float _7855 = _602_fa_layers_c.x;\n    if (_602_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_602_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7849 *= _6677.y;\n            _7850 *= _6677.z;\n            _7852 *= _6666.w;\n        }\n        if (_602_fa_layers_c.z > 1.5f)\n        {\n            _7853 *= mrt.x;\n            _7855 *= mrt.w;\n        }\n    }\n    Surface _7874 = { _6570.xyz, _6570.w, _7844, clamp(_602_fa_pbr.x * _6638.z, 0.0f, 1.0f), clamp(_602_fa_pbr.y * _6638.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_602_fa_maps.y * (_6677.x - 1.0f)), _602_fa_emissive.xyz + (_602_fa_model_emissive.xyz * _6707), _7849, _7850, _602_fa_layers_b.xyz, _7852, _7853, _602_fa_layers_a.w, _7855, _602_fa_layers_c.y, _602_fa_layers_d.xyz };\n    return _7874;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1771 = rect.zw - rect.xy;\n    float2 _1775 = _1771 * atlas;\n    float2 _1779 = ddx * _1775;\n    float2 _1783 = ddy * _1775;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1771), clamp(0.5f * log2(max(max(dot(_1779, _1779), dot(_1783, _1783)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1816 = _602_fa_counts.y < 0.5f;\n    bool _1823;\n    if (!_1816)\n    {\n        _1823 = _602_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1823 = _1816;\n    }\n    if (_1823)\n    {\n        return;\n    }\n    float3 _1829 = ddx(world_pos);\n    float3 _1832 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1836 = fa_cluster_texel(param);\n    int _1840 = int(_1836.w);\n    if (_1840 < 1)\n    {\n        return;\n    }\n    int _1850 = int(_602_fa_counts.y + 0.5f);\n    int param_1 = _1850;\n    float4 _1854 = fa_light_texel(param_1);\n    float2 _1857 = _1854.yz;\n    int _1861 = int(_1854.w);\n    int param_2 = _1850 + 1;\n    float4 _1866 = fa_light_texel(param_2);\n    float _1867 = _1866.x;\n    int _1873 = int(_602_fa_counts.w + 0.5f) - 1;\n    int _1877 = int(_1836.z);\n    float3 _2142;\n    for (int k = 0; k < _1840; k++)\n    {\n        int _1890 = _1877 + k;\n        int param_3 = _1861 + (_1890 >> 2);\n        int _1907 = (_1850 + 2) + (int(fa_light_texel(param_3)[_1890 & 3]) * 7);\n        int param_4 = _1907 + 6;\n        float4 _1912 = fa_light_texel(param_4);\n        if (((int(_1912.w + 0.5f) >> _1873) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1907;\n        float4 _1927 = fa_light_texel(param_5);\n        int param_6 = _1907 + 1;\n        float4 _1932 = fa_light_texel(param_6);\n        int param_7 = _1907 + 2;\n        float4 _1937 = fa_light_texel(param_7);\n        float3 _1940 = _1927.xyz;\n        float _1945 = dot(_1940, world_pos) + _1927.w;\n        float3 _1947 = _1932.xyz;\n        float _1952 = dot(_1947, world_pos) + _1932.w;\n        float3 _1954 = _1937.xyz;\n        float _1959 = dot(_1954, world_pos) + _1937.w;\n        bool _1964 = abs(_1945) > 0.5f;\n        bool _1972;\n        if (!_1964)\n        {\n            _1972 = abs(_1952) > 0.5f;\n        }\n        else\n        {\n            _1972 = _1964;\n        }\n        bool _1980;\n        if (!_1972)\n        {\n            _1980 = abs(_1959) > 0.5f;\n        }\n        else\n        {\n            _1980 = _1972;\n        }\n        if (_1980)\n        {\n            continue;\n        }\n        float _1995 = clamp(dot(geo_normal, normalize(_1954)) * _1912.z, 0.0f, 1.0f);\n        if (_1995 <= 0.0f)\n        {\n            continue;\n        }\n        float _2015 = (clamp((0.5f - abs(_1959)) * 10.0f, 0.0f, 1.0f) * _1995) * _1912.x;\n        float2 _2023 = float2(_1945 + 0.5f, 0.5f - _1952);\n        float2 _2033 = float2(dot(_1940, _1829), dot(_1947, _1829));\n        float2 _2043 = float2(dot(_1940, _1832), dot(_1947, _1832));\n        int param_8 = _1907 + 5;\n        float4 _2048 = fa_light_texel(param_8);\n        int param_9 = _1907 + 3;\n        float4 _2053 = fa_light_texel(param_9);\n        int param_10 = _1907 + 4;\n        float4 _2058 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2048.xyz;\n        bool _2068 = _2053.z > _2053.x;\n        if (_2068)\n        {\n            float4 param_11 = _2053;\n            float2 param_12 = _2023;\n            float2 param_13 = _1857;\n            float2 param_14 = _2033;\n            float2 param_15 = _2043;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1867 > 0.5f) && (_1867 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2094 = fa_dc_to_linear(param_16);\n                float4 _7924 = tx;\n                _7924.x = _2094.x;\n                _7924.y = _2094.y;\n                _7924.z = _2094.z;\n                tx = _7924;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2015 * tex_a) * _2048.w, 0.0f, 1.0f).xxx);\n        if (_2058.z > _2058.x)\n        {\n            float4 param_17 = _2058;\n            float2 param_18 = _2023;\n            float2 param_19 = _1857;\n            float2 param_20 = _2033;\n            float2 param_21 = _2043;\n            float4 _2138 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1867 > 1.5f)\n            {\n                float3 param_22 = _2138.xyz;\n                float3 _2148 = fa_dc_to_srgb(param_22);\n                _2142 = _2148;\n            }\n            else\n            {\n                _2142 = _2138.xyz;\n            }\n            float3 _2157 = (_2142 * 2.0f) - 1.0f.xxx;\n            float2 _2162 = _2157.xy * _1912.y;\n            float3 _2184 = (normalize(_1940) * _2162.x) + (normalize(_1947) * _2162.y);\n            float3 _2187 = normalize(normal);\n            normal = normalize(lerp(_2187, normalize((_2187 * max(_2157.z, 0.0500000007450580596923828125f)) + (_2184 - (_2187 * dot(_2187, _2184)))), clamp(_2015 * (_2068 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4211 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4218 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4221 = int(_4211);\n    int _4224 = int(_4218);\n    float _4234 = _4218 - float(_4224);\n    int _4289 = (_4221 * 9) + _4224;\n    int _4309 = ((_4221 + 1) * 9) + _4224;\n    return lerp(lerp(_4285[_4289], _4285[_4289 + 1], _4234), lerp(_4285[_4309], _4285[_4309 + 1], _4234), _4211 - float(_4221));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7767 = false;\n    float _7768 = 1.0f;\n    float _7769 = 1.0f;\n    float _7770 = 1.0f;\n    float _7771 = 0.0f;\n    float _7772 = 0.0f;\n    float _7773 = 0.0f;\n    float _7774 = 0.0f;\n    float _7776 = 1.0f;\n    bool _7777 = false;\n    float3 _7778 = 0.0f.xxx;\n    float _7779 = 1.0f;\n    float _7780 = 1.0f;\n    float _7781 = 1.0f;\n    float _7782 = 0.0f;\n    float _7783 = 0.0f;\n    float3 _7784 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7785 = float3(0.0f, 0.0f, 1.0f);\n    float _7786 = 1.0f;\n    float _7787 = 1.0f;\n    float _4360 = clamp(s.specular, 0.0f, 1.0f);\n    float _4364 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4369 = (_4360 != 1.0f) || (_4364 != 1.5f);\n    bool _4378;\n    if (!_4369)\n    {\n        _4378 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4378 = _4369;\n    }\n    if (_4378)\n    {\n        float _4386 = (_4364 - 1.0f) / (_4364 + 1.0f);\n        f0 = lerp(min((_4386 * _4386).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4360, s.albedo, metallic.xxx);\n        _7768 = lerp(_4360, 1.0f, metallic);\n        _7767 = true;\n    }\n    float _4413 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4413 > 0.0f)\n    {\n        float _4421 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7771 = _4413;\n        _7772 = _4421;\n        float _4428 = _4421 * _4421;\n        _7773 = _4428;\n        _7774 = _4428 * _4428;\n        float _4440 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7776 = _4440;\n        _7769 = 1.0f - (_4413 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4440, 0.0f, 1.0f), 5.0f))));\n        _7767 = true;\n    }\n    float3 _4459 = max(s.sheen_color, 0.0f.xxx);\n    float _4468 = max(_4459.x, max(_4459.y, _4459.z));\n    if (_4468 > 0.0f)\n    {\n        float _4476 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7777 = true;\n        _7778 = _4459;\n        _7779 = _4476;\n        _7780 = _4476 * _4476;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4476;\n        float _4493 = fa_sheen_albedo(param, param_1);\n        _7782 = _4493;\n        _7781 = 1.0f - min(_4468 * _4493, 1.0f);\n        _7767 = true;\n    }\n    _7770 = _7769 * _7781;\n    float _4512 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4512 != 0.0f)\n    {\n        float3 _4527 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4527;\n        if (dot(_4527, _4527) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4539 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4539.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4539.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4539.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4543 = t;\n        float3 _4544 = normalize(_4543);\n        t = _4544;\n        float3 _4569 = normalize((_4544 * cos(s.anisotropy_rotation)) + ((cross(n, _4544) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7784 = _4569;\n        _7785 = cross(n, _4569);\n        float _4579 = roughness * roughness;\n        float _4585 = lerp(_4579, 1.0f, _4512 * _4512);\n        bool _4587 = _4512 > 0.0f;\n        _7786 = _4587 ? _4585 : _4579;\n        _7787 = _4587 ? _4579 : _4585;\n        _7783 = _4512;\n        _7767 = true;\n    }\n    FaLayers _7809 = { _7767, _7768, _7769, _7770, _7771, _7772, _7773, _7774, i.world_normal, _7776, _7777, _7778, _7779, _7780, _7781, _7782, _7783, _7784, _7785, _7786, _7787 };\n    return _7809;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3441_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3441_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_602_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3382 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3382;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3992 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3997 = _602_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3992 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3997)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _602_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3992;\n            }\n        }\n        else\n        {\n            amb = _602_fa_ambient.xyz * _3992;\n        }\n    }\n    bool _4048 = _602_fa_rpa_tile.w > 0.0f;\n    if (_4048)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _602_fa_rpa_tile.xy;\n            float param_4 = _602_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _602_fa_rpa_tile.w);\n        }\n    }\n    bool _4079 = _602_fa_rpb_tile.w > 0.0f;\n    if (_4079)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _602_fa_rpb_tile.xy;\n            float param_7 = _602_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _602_fa_rpb_tile.w);\n        }\n    }\n    if ((_3997 || _4048) || _4079)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_602_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _602_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_602_fa_cl_info.x) + int(_602_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_602_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5353;\n    if (fa_lm.z > 0.5f)\n    {\n        _5353 = 0.0f;\n    }\n    else\n    {\n        _5353 = 1.0f - clamp(_602_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5364 = _5353 < 1.0f;\n    bool _5370;\n    if (_5364)\n    {\n        int param = li;\n        _5370 = fa_light_baked(param);\n    }\n    else\n    {\n        _5370 = _5364;\n    }\n    return _5370 ? _5353 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _670_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _670_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _789 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _802 = (c - (ru * hx)) - p;\n        float3 _808 = ru * (2.0f * hx);\n        float _814 = max(dot(_808, _808), 9.9999999392252902907785028219223e-09f);\n        float _818 = dot(_802, _808);\n        float t = clamp((-_818) / _814, 0.0f, 1.0f);\n        if (_789)\n        {\n            float _833 = dot(r, _808);\n            float _839 = _814 - (_833 * _833);\n            if (abs(_839) > (9.9999997473787516355514526367188e-06f * _814))\n            {\n                t = clamp(((dot(r, _802) * _833) - _818) / _839, 0.0f, 1.0f);\n            }\n        }\n        return (p + _802) + (_808 * t);\n    }\n    float3 q = p;\n    float _871 = dot(r, axis);\n    bool _879;\n    if (_789)\n    {\n        _879 = abs(_871) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _879 = _789;\n    }\n    if (_879)\n    {\n        float _889 = dot(c - p, axis) / _871;\n        if (_889 > 0.0f)\n        {\n            q = p + (r * _889);\n        }\n    }\n    float3 _902 = q - c;\n    float2 xy = float2(dot(_902, ru), dot(_902, uu));\n    if (shape > 0.5f)\n    {\n        float _917 = length(xy);\n        if (_917 > hx)\n        {\n            xy *= (hx / _917);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _550 = abs(d);\n    float _552 = _550.x;\n    float _554 = _550.y;\n    bool _555 = _552 >= _554;\n    bool _563;\n    if (_555)\n    {\n        _563 = _552 >= _550.z;\n    }\n    else\n    {\n        _563 = _555;\n    }\n    int _564;\n    if (_563)\n    {\n        _564 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _579;\n        if (_554 >= _550.z)\n        {\n            _579 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _579 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _564 = _579;\n    }\n    return _564;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _709 = dot(d, right);\n    float _713 = dot(d, up);\n    float _724;\n    if (((_709 * _709) + (_713 * _713)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _724 = atan2(_713, _709) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _724 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_724 - floor(_724)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _955 = fa_light_base(param);\n    bool _959 = _602_fa_ambient.w > 4.5f;\n    int param_1 = _955;\n    float4 _963 = fa_light_texel(param_1);\n    int param_2 = _955 + 1;\n    float4 _968 = fa_light_texel(param_2);\n    float _971 = _968.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _983 = _959 && (_971 > 2.5f);\n    fa_light_is_area = _983;\n    bool _985 = _971 < 0.5f;\n    float3 l;\n    if (_985)\n    {\n        l = normalize(_963.xyz);\n        if (_959)\n        {\n            int param_3 = _955 + 6;\n            float4 _999 = fa_light_texel(param_3);\n            if (_999.z > 0.5f)\n            {\n                int param_4 = _955 + 4;\n                float4 _1009 = fa_light_texel(param_4);\n                int param_5 = _955 + 5;\n                float4 _1014 = fa_light_texel(param_5);\n                float2 param_6 = _999.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1009.xyz) * _1009.w, (-dot(world_pos, _1014.xyz)) * _1014.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1044 = _963.xyz;\n        float3 _1046 = _1044 - world_pos;\n        float3 to_light = _1046;\n        float _1049 = length(_1046);\n        float reach = _1049;\n        bool front = true;\n        if (_983)\n        {\n            int param_8 = _955 + 7;\n            reach = max(_1049 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _955 + 4;\n            float4 _1073 = fa_light_texel(param_9);\n            int param_10 = _955 + 5;\n            float4 _1078 = fa_light_texel(param_10);\n            int param_11 = _955 + 6;\n            float4 _1083 = fa_light_texel(param_11);\n            float _1084 = _1083.w;\n            int param_12 = _955 + 2;\n            float3 _1091 = normalize(fa_light_texel(param_12).xyz);\n            bool _1093 = _1084 > 1.5f;\n            bool _1101;\n            if (!_1093)\n            {\n                _1101 = dot(_1091, to_light) < 0.0f;\n            }\n            else\n            {\n                _1101 = _1093;\n            }\n            front = _1101;\n            float3 r = 0.0f.xxx;\n            float3 _1110 = _602_fa_camera_pos.xyz - world_pos;\n            bool _1114 = dot(n, n) > 0.5f;\n            bool _1122;\n            if (_1114)\n            {\n                _1122 = dot(_1110, _1110) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1122 = _1114;\n            }\n            if (_1122)\n            {\n                r = reflect(-normalize(_1110), normalize(n));\n            }\n            float3 param_13 = _1044;\n            float3 param_14 = _1091;\n            float3 param_15 = _1073.xyz;\n            float3 param_16 = _1078.xyz;\n            float param_17 = _1073.w;\n            float param_18 = _1078.w;\n            float param_19 = _1084;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1158 = length(to_light);\n        dist = _1158;\n        l = to_light / max(_1158, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1172 = reach / max(_963.w, 0.001000000047497451305389404296875f);\n        float _1178 = clamp(1.0f - (_1172 * _1172), 0.0f, 1.0f);\n        float _1180;\n        if (front)\n        {\n            _1180 = _1178 * _1178;\n        }\n        else\n        {\n            _1180 = 0.0f;\n        }\n        atten = _1180;\n        bool _1191 = _971 < 2.5f;\n        if ((_971 > 1.5f) && _1191)\n        {\n            int param_22 = _955 + 2;\n            float4 _1199 = fa_light_texel(param_22);\n            float _1209 = _1199.w;\n            int param_23 = _955 + 3;\n            float4 _1214 = fa_light_texel(param_23);\n            float _1215 = _1214.x;\n            float cos_inner = _1215;\n            if (_1215 > 1.5f)\n            {\n                cos_inner = lerp(_1209, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1209, cos_inner, dot(-l, normalize(_1199.xyz)));\n        }\n        if (_959 && (_971 < 1.5f))\n        {\n            int param_24 = _955 + 6;\n            float4 _1239 = fa_light_texel(param_24);\n            if (_1239.z > 0.5f)\n            {\n                float3 _1247 = -to_light;\n                int param_25 = _955 + 4;\n                int param_26 = _955 + 5;\n                float3 _1261 = fa_light_texel(param_25).xyz;\n                float3 _1265 = fa_light_texel(param_26).xyz;\n                float3 _1274 = float3(dot(_1247, _1261), dot(_1247, _1265), dot(_1247, cross(_1261, _1265)));\n                float3 param_27 = _1274;\n                int _1278 = fa_cube_face(param_27);\n                int param_28 = _1278;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1305 = float2(dot(_1274, cross(param_29, param_30)), dot(_1274, param_30)) / max(dot(_1274, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1309 = _1278 / 3;\n                float2 param_31 = _1239.xy + (float2(float(_1278 - (_1309 * 3)), float(_1309)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1305.x), 0.5f - (0.5f * _1305.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _955 + 7;\n            float4 _1339 = fa_light_texel(param_33);\n            if (_1339.z > 0.5f)\n            {\n                int param_34 = _955 + 2;\n                int param_35 = _955 + 4;\n                int param_36 = _955 + 5;\n                float2 param_37 = _1339.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_959 && _1191)\n            {\n                int param_42 = _955 + 6;\n                float4 _1386 = fa_light_texel(param_42);\n                int param_43 = _955 + 7;\n                float4 _1391 = fa_light_texel(param_43);\n                bool _1394 = _1386.z > 0.5f;\n                bool _1401;\n                if (!_1394)\n                {\n                    _1401 = _1391.z > 0.5f;\n                }\n                else\n                {\n                    _1401 = _1394;\n                }\n                if (_1401)\n                {\n                    int param_44 = _955 + 2;\n                    float4 _1408 = fa_light_texel(param_44);\n                    float3 _1412 = normalize(_1408.xyz);\n                    int param_45 = _955 + 4;\n                    float4 _1417 = fa_light_texel(param_45);\n                    int param_46 = _955 + 5;\n                    float4 _1422 = fa_light_texel(param_46);\n                    if (_1394)\n                    {\n                        float3 _1430 = -to_light;\n                        float _1437 = _1408.w;\n                        float _1453 = 0.5f / max(dot(_1430, _1412) * (sqrt(max(1.0f - (_1437 * _1437), 0.0f)) / max(_1437, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1386.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1430, _1417.xyz) * _1453), 0.5f - (dot(_1430, _1422.xyz) * _1453));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1391.z > 0.5f)\n                    {\n                        float2 param_49 = _1391.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1412;\n                        float3 param_52 = _1417.xyz;\n                        float3 param_53 = _1422.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7755 = _968.xyz * atten;\n    if (_959)\n    {\n        _7755 *= fa_light_tint;\n    }\n    int _1522;\n    if (_985)\n    {\n        _1522 = 0;\n    }\n    else\n    {\n        _1522 = ((_971 > 1.5f) && (_971 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7766 = { l, _7755, atten, 1.0f, dist, _1522 };\n    return _7766;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2259;\n    if (i == 0)\n    {\n        _2259 = _2269_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2275;\n        if (i == 1)\n        {\n            _2275 = _2269_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2283;\n            if (i == 2)\n            {\n                _2283 = _2269_fa_shadow_split.z;\n            }\n            else\n            {\n                _2283 = _2269_fa_shadow_split.w;\n            }\n            _2275 = _2283;\n        }\n        _2259 = _2275;\n    }\n    return _2259;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2316 = fa_shadow_depth(param, param_1);\n    float _2320;\n    if (conv.x < 0.5f)\n    {\n        _2320 = _2316;\n    }\n    else\n    {\n        _2320 = (conv.y * conv.z) / (conv.z - (_2316 * (conv.z - conv.y)));\n    }\n    return _2320;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2247 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2247), sin(_2247)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2366 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2375;\n        if (k < 0.0f)\n        {\n            _2375 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2375 = k;\n        }\n        float _2395 = clamp((_2375 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2366;\n            float2 _2414 = fa_shadow_vogel(param_3, param_4, param_5) * _2395;\n            float2 param_6 = uv + (_2414 * _2269_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2426 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2426 < (zr - (length(_2414) * plane)))\n            {\n                sum += _2426;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2452 = sum / cnt;\n        float _2462;\n        if (k < 0.0f)\n        {\n            _2462 = (-k) / max(_2452, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2462 = k;\n        }\n        radius = clamp(((max(zr - _2452, 0.0f) * unit) * _2462) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2484 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2484; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2484;\n        float param_11 = _2366;\n        float2 _2503 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2503 * _2269_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2503) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2484);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2545 = max(_2269_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2550 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2556 = sqrt(1.0f - (_2550 * _2550));\n    float _2563 = min(_2556 / max(_2550, 0.20000000298023223876953125f), 4.0f);\n    float _2568;\n    if (_2269_fa_shadow_bias.y > 0.0f)\n    {\n        _2568 = _2269_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2568 = 1.5f * _2269_fa_shadow_info[ci].x;\n    }\n    float4 _2593 = mul(float4(world + (n * (_2568 * _2556)), 1.0f), _2269_fa_shadow_mat[ci]);\n    float _2600 = _2593.x;\n    bool _2603 = _2600 < _2269_fa_shadow_rect[ci].x;\n    bool _2612;\n    if (!_2603)\n    {\n        _2612 = _2600 > _2269_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2612 = _2603;\n    }\n    bool _2621;\n    if (!_2612)\n    {\n        _2621 = _2593.y < _2269_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2621 = _2612;\n    }\n    bool _2630;\n    if (!_2621)\n    {\n        _2630 = _2593.y > _2269_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2630 = _2621;\n    }\n    bool _2637;\n    if (!_2630)\n    {\n        _2637 = _2593.z > 1.0f;\n    }\n    else\n    {\n        _2637 = _2630;\n    }\n    if (_2637)\n    {\n        return -1.0f;\n    }\n    float _2645;\n    if (_2269_fa_shadow_bias.x > 0.0f)\n    {\n        _2645 = _2269_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2645 = 1.5f * _2269_fa_shadow_info[ci].x;\n    }\n    float2 param = _2593.xy;\n    float4 param_1 = _2269_fa_shadow_rect[ci];\n    float param_2 = _2593.z - ((_2645 * (1.0f + (0.5f * _2563))) / _2545);\n    float param_3 = _2269_fa_shadow_info[ci].x;\n    float param_4 = _2545;\n    float param_5 = _2545 * 0.25f;\n    float param_6 = ((_2269_fa_shadow_info[ci].x * min(_2563, 3.0f)) * 0.5f) / _2545;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2269_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2269_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_602_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3023 = int(_2269_fa_shadow_cfg.x + 0.5f);\n    if (_3023 < 1)\n    {\n        return 1.0f;\n    }\n    float _3038 = dot(world - _2269_fa_shadow_eye.xyz, _2269_fa_shadow_fwd.xyz);\n    int param = _3023 - 1;\n    if (_3038 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3050 = _3023 > 1;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3038 > _2269_fa_shadow_split.x;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 1;\n    }\n    bool _3061 = _3023 > 2;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3038 > _2269_fa_shadow_split.y;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 2;\n    }\n    bool _3072 = _3023 > 3;\n    bool _3079;\n    if (_3072)\n    {\n        _3079 = _3038 > _2269_fa_shadow_split.z;\n    }\n    else\n    {\n        _3079 = _3072;\n    }\n    if (_3079)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3023)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3105 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3105;\n        if (_3105 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2269_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3130;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3130 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3130 = _2269_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3149 = _2269_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3130, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3160 = clamp((_3038 - (fa_shadow_split_at(param_7) - _3149)) / _3149, 0.0f, 1.0f);\n        if (_3160 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3023)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3181 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3181;\n                if (_3181 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3160);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2703 = _602_fa_pbr.z < 0.5f;\n    bool _2710;\n    if (!_2703)\n    {\n        _2710 = _2269_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2710 = _2703;\n    }\n    if (_2710)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2269_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2723 = fa_light_texel(param);\n    float _2724 = _2723.x;\n    if (_2724 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2733 = int(_2724 + 0.5f);\n    int param_1 = _2733;\n    float4 _2737 = fa_light_texel(param_1);\n    int param_2 = _2733 + 1;\n    float4 _2742 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2745 = _2737.y;\n    if (_2745 > 0.0f)\n    {\n        float _2762 = 1.0f - smoothstep(0.75f * _2745, _2745, length(world - _2269_fa_shadow_eye.xyz));\n        fade = _2762;\n        if (_2762 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2737.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2786 = (_2733 + 2) + (face * 6);\n    int param_4 = _2786;\n    int param_5 = _2786 + 1;\n    int param_6 = _2786 + 3;\n    float4 _2800 = fa_light_texel(param_6);\n    int param_7 = _2786 + 4;\n    float4 _2805 = fa_light_texel(param_7);\n    int param_8 = _2786 + 5;\n    float4 _2810 = fa_light_texel(param_8);\n    float _2822 = _2810.x * max(dot(_2800, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2827 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2850 = clamp(dot(n, _2800.xyz), -1.0f, 1.0f);\n    float _2869 = min(sqrt(1.0f - (_2850 * _2850)) / max(abs(dot(n, world - lpos)) / max(dot(_2800, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2872 = _2742.y;\n    float _2874;\n    if (_2872 > 0.0f)\n    {\n        _2874 = _2872;\n    }\n    else\n    {\n        _2874 = 1.5f * _2822;\n    }\n    float4 _2894 = float4(world + (n * (_2874 * sqrt(1.0f - (_2827 * _2827)))), 1.0f);\n    float _2898 = dot(_2800, _2894);\n    float _2901 = _2810.y;\n    if (_2898 < _2901)\n    {\n        return 1.0f;\n    }\n    float2 _2916 = float2(dot(fa_light_texel(param_4), _2894), dot(fa_light_texel(param_5), _2894)) / _2898.xx;\n    float _2918 = _2916.x;\n    bool _2921 = _2918 < _2805.x;\n    bool _2930;\n    if (!_2921)\n    {\n        _2930 = _2918 > _2805.z;\n    }\n    else\n    {\n        _2930 = _2921;\n    }\n    bool _2939;\n    if (!_2930)\n    {\n        _2939 = _2916.y < _2805.y;\n    }\n    else\n    {\n        _2939 = _2930;\n    }\n    bool _2948;\n    if (!_2939)\n    {\n        _2948 = _2916.y > _2805.w;\n    }\n    else\n    {\n        _2948 = _2939;\n    }\n    if (_2948)\n    {\n        return 1.0f;\n    }\n    float _2954 = _2742.x;\n    float _2956;\n    if (_2954 > 0.0f)\n    {\n        _2956 = _2954;\n    }\n    else\n    {\n        _2956 = 1.5f * _2822;\n    }\n    float2 param_9 = _2916;\n    float4 param_10 = _2805;\n    float param_11 = _2898 - (_2956 * (1.0f + (0.5f * _2869)));\n    float param_12 = _2822;\n    float param_13 = 1.0f;\n    float param_14 = _2810.z * 0.25f;\n    float param_15 = (_2822 * min(_2869, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2901, _2810.z);\n    int param_17 = int(_2737.z + 0.5f);\n    float param_18 = _2737.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5097 = _602_fa_ct_a.x < 0.5f;\n    bool _5104;\n    if (!_5097)\n    {\n        _5104 = _2269_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5104 = _5097;\n    }\n    if (_5104)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2269_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5117 = fa_light_texel(param);\n    float _5118 = _5117.y;\n    float len = _5118;\n    if (_5118 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5130 = length(world - _602_fa_camera_pos.xyz);\n    float _5140 = 1.0f - smoothstep(0.5f * _602_fa_ct_b.x, _602_fa_ct_b.x, _5130);\n    if (_5140 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5146 = len;\n    float _5149 = min(_5146, 0.89999997615814208984375f * dist);\n    len = _5149;\n    float _5154 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5130);\n    float _5159 = _5154 + (0.5f * _5149);\n    float3 _5165 = world + (gn * _5154);\n    float _5167 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5231;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5182 = (float(k) + _5167) * 0.083333335816860198974609375f;\n        float3 _5190 = _5165 + (l * (_5182 * len));\n        float4 _5196 = float4(_5190, 1.0f);\n        float _5202 = dot(_602_fa_ct_vpw, _5196);\n        if (_5202 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5222 = float2(dot(_602_fa_ct_vpx, _5196), dot(_602_fa_ct_vpy, _5196)) / _5202.xx;\n        float _5226 = _5222.x * 0.5f;\n        float _5227 = _5226 + 0.5f;\n        if (_602_fa_ct_a.y > 0.5f)\n        {\n            _5231 = (_5222.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5231 = 0.5f - (_5222.y * 0.5f);\n        }\n        bool _5247 = _5227 < 0.0f;\n        bool _5254;\n        if (!_5247)\n        {\n            _5254 = _5227 >= 1.0f;\n        }\n        else\n        {\n            _5254 = _5247;\n        }\n        bool _5261;\n        if (!_5254)\n        {\n            _5261 = _5231 < 0.0f;\n        }\n        else\n        {\n            _5261 = _5254;\n        }\n        bool _5268;\n        if (!_5261)\n        {\n            _5268 = _5231 >= 1.0f;\n        }\n        else\n        {\n            _5268 = _5261;\n        }\n        if (_5268)\n        {\n            break;\n        }\n        float4 _5287 = fa_screen_tex.Load(int3(int2(float2(_5227, _5231) * _602_fa_ct_a.zw), 0));\n        if (_5287.w < 0.5f)\n        {\n            continue;\n        }\n        float _5306 = (dot(_602_fa_ct_fwd.xyz, _5190) + _602_fa_ct_fwd.w) - _5287.x;\n        if ((_5306 > _5154) && (_5306 < _5159))\n        {\n            occ = max(occ, (1.0f - (_5182 * _5182)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5227, 0.5f - _5226), min(_5231, 1.0f - _5231))));\n        }\n    }\n    return 1.0f - (occ * _5140);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5409 = fa_baked_keep(param);\n    if (_5409 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7822 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7822;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5435 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7824 = _5435.color;\n    float _7825 = _5435.attenuation;\n    float _7826 = _5435.shadow;\n    bool _5438 = _5435.type == 0;\n    if (_5438 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5435.direction;\n        float _5449 = fa_shadow_factor(param_5, param_6);\n        _7826 = _5449;\n        _7824 *= _5449;\n    }\n    else\n    {\n        bool _5460 = _5435.type != 0;\n        bool _5466;\n        if (_5460)\n        {\n            _5466 = _7825 > 0.0f;\n        }\n        else\n        {\n            _5466 = _5460;\n        }\n        if (_5466)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5435.direction;\n            float _5485 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7826 = _5485;\n            _7824 *= _5485;\n        }\n    }\n    bool _5495 = _602_fa_ct_a.x > 0.5f;\n    bool _5501;\n    if (_5495)\n    {\n        _5501 = _7825 > 0.0f;\n    }\n    else\n    {\n        _5501 = _5495;\n    }\n    if (_5501)\n    {\n        float _5508;\n        if (_5438)\n        {\n            _5508 = 1000000000.0f;\n        }\n        else\n        {\n            _5508 = _5435._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5435.direction;\n        float param_18 = _5508;\n        float _5526 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7826 *= _5526;\n        _7824 *= _5526;\n    }\n    float _5539 = _7825;\n    float _5540 = _5539 * _5409;\n    _7825 = _5540;\n    float3 _5544 = _7824;\n    float3 _5545 = _5544 * _5409;\n    _7824 = _5545;\n    LightSample _7841 = { _5435.direction, _5545, _5540, _7826, _5435._distance, _5435.type };\n    return _7841;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5579 = v - (n * dot(v, n));\n    float3 t = _5579;\n    float _5583 = dot(_5579, _5579);\n    float l2 = _5583;\n    if (_5583 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5593;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5593 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5593 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5593;\n        l2 = dot(_5593, _5593);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5628 = dot(a, a);\n    float _5632 = dot(b, b);\n    if ((_5628 < 1.0000000195414813782625560981111e-24f) || (_5632 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5646 = a * rsqrt(_5628);\n    float3 _5651 = b * rsqrt(_5632);\n    float _5655 = dot(_5646, _5651);\n    float _5658 = abs(_5655);\n    float g = (((((((((((0.0416471660137176513671875f * _5658) - 0.1924748718738555908203125f) * _5658) + 0.4179156124591827392578125f) * _5658) - 0.616057217121124267578125f) * _5658) + 0.777722418308258056640625f) * _5658) - 0.999542415142059326171875f) * _5658) + 1.570791721343994140625f;\n    if (_5655 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5655 * _5655), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5646, _5651) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5715 = a.z > 0.0f;\n    bool _5719 = b.z > 0.0f;\n    if (_5715 && _5719)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5715 != _5719)\n        {\n            float3 _5754 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5754.z = 0.0f;\n            if (_5715)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5754;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5754;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5754;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5754;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5803 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5829 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5855 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5881 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5803;\n    float3 param_1 = _5829;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5829;\n    float3 param_7 = _5855;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5855;\n    float3 param_13 = _5881;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5881;\n    float3 param_19 = _5803;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6031 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6055 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6071 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6031;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6055;\n    float4 param_9 = m;\n    float3 param_10 = _6031;\n    float3 param_11 = _6055;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6071;\n    float4 param_14 = m;\n    float3 param_15 = _6031;\n    float3 param_16 = _6071;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6129 = fa_light_base(param);\n    int param_1 = _6129;\n    int param_2 = _6129 + 1;\n    int param_3 = _6129 + 2;\n    int param_4 = _6129 + 4;\n    float4 _6151 = fa_light_texel(param_4);\n    int param_5 = _6129 + 5;\n    float4 _6156 = fa_light_texel(param_5);\n    int param_6 = _6129 + 6;\n    float4 _6161 = fa_light_texel(param_6);\n    float _6162 = _6161.w;\n    float3 _6167 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6169 = _6162 < 1.5f;\n    bool _6176;\n    if (_6169)\n    {\n        _6176 = dot(normalize(fa_light_texel(param_3).xyz), _6167) >= 0.0f;\n    }\n    else\n    {\n        _6176 = _6169;\n    }\n    if (_6176)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6185 = (_6162 > 0.5f) && _6169;\n    float _6189 = _6185 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6192 = _6151.xyz;\n    float _6194 = _6151.w;\n    float3 _6200 = _6156.xyz;\n    float _6202 = _6156.w;\n    float3 up = _6200 * (_6202 * _6189);\n    float _6208;\n    if (_6185)\n    {\n        _6208 = (3.1415927410125732421875f * _6194) * _6194;\n    }\n    else\n    {\n        _6208 = (4.0f * _6194) * _6202;\n    }\n    if (_6162 > 1.5f)\n    {\n        float3 _6234 = cross(_6192, -_6167);\n        float3 perp = _6234;\n        float _6238 = dot(_6234, _6234);\n        float3 _6241;\n        if (_6238 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6241 = perp * rsqrt(_6238);\n        }\n        else\n        {\n            _6241 = _6200;\n        }\n        perp = _6241;\n        up = _6241 * _6202;\n    }\n    float _6262 = max(_6208, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6272 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6272;\n    float3 param_10 = n;\n    float3 param_11 = _6167;\n    float3 _6280 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6272;\n    float3 param_13 = n;\n    float3 param_14 = _6192 * (_6194 * _6189);\n    float3 _6288 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6272;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6296 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6162;\n    float3 param_20 = _6280;\n    float3 param_21 = _6288;\n    float3 param_22 = _6296;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6315 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6315;\n    float2 param_26 = _6315 + float2(64.0f, 0.0f);\n    float4 _6325 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6162;\n    float3 param_29 = _6280;\n    float3 param_30 = _6288;\n    float3 param_31 = _6296;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6325.x) + ((f90.xxx - f0) * _6325.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6167, _6167)) + _6262) / _6262) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4834 = 1.0f / alpha;\n    return ((2.0f + _4834) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4834)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4869 = max(dot(L.nc, l), 0.0f);\n    float _4875 = max(dot(L.nc, h), 0.0f);\n    float _4884 = ((_4875 * _4875) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4884) * _4884)) * (0.5f / max(lerp((2.0f * _4869) * L.coat_ndv, _4869 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4869)) * _4869;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6393;\n    if (L.sheen_on)\n    {\n        _6393 = L.sheen_scale;\n    }\n    else\n    {\n        _6393 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6393);\n    float3 _6406 = normalize(l + v);\n    int param_10 = li;\n    float3 _6417 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6426 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6406), 0.0f);\n        float param_13 = _6426;\n        float param_14 = ndv;\n        result += ((L.sheen * _6417) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6426)) * _6426) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6406;\n        float param_18 = max(dot(v, _6406), 0.0f);\n        result += (_6417 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4737 = tdh / at;\n    float _4741 = bdh / ab;\n    float _4753 = ((_4737 * _4737) + (_4741 * _4741)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4753) * _4753);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4933 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5012 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5012) * _5012);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4933);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4933));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4143 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4146 = _4143.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4146 * _4146, exp2((-9.27999973297119140625f) * ndv)) * _4146) + _4143.y)) + _4143.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3402 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3405 = _3402.x;\n    float _3407 = _3402.z;\n    float2 e = float2(_3405, _3407);\n    if (_3402.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3407)) * ((_3405 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3405)) * ((_3407 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3454;\n    if (lv == 0)\n    {\n        _3454 = 0.0f;\n    }\n    else\n    {\n        _3454 = res + 2.0f;\n    }\n    float _3464;\n    if (lv == 0)\n    {\n        _3464 = 0.0f;\n    }\n    else\n    {\n        _3464 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3454, _3464)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3509;\n    if (res > 64.5f)\n    {\n        _3509 = 5.0f;\n    }\n    else\n    {\n        _3509 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3524 = clamp(rough, 0.0f, 1.0f) * (_3509 - 1.0f);\n    int _3531 = int(min(floor(_3524), _3509 - 2.0f));\n    float _3536 = _3524 - float(_3531);\n    float3 param = d;\n    float2 _3540 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3531;\n    float2 param_4 = _3540;\n    float3 _3550 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3536 < 0.00200000009499490261077880859375f)\n    {\n        return _3550;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3531 + 1;\n    float2 param_8 = _3540;\n    return lerp(_3550, fa_probe_level(param_5, param_6, param_7, param_8), _3536.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3620 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3627 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3634 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3640 = dot(bx.xyz, d);\n    float _3644 = dot(by.xyz, d);\n    float _3648 = dot(bz.xyz, d);\n    float _3654;\n    if (_3640 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3654 = (1.0f - _3620) / _3640;\n    }\n    else\n    {\n        float _3668;\n        if (_3640 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3668 = ((-1.0f) - _3620) / _3640;\n        }\n        else\n        {\n            _3668 = 1000000015047466219876688855040.0f;\n        }\n        _3654 = _3668;\n    }\n    float tx = _3654;\n    float _3685;\n    if (_3644 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3685 = (1.0f - _3627) / _3644;\n    }\n    else\n    {\n        float _3698;\n        if (_3644 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3698 = ((-1.0f) - _3627) / _3644;\n        }\n        else\n        {\n            _3698 = 1000000015047466219876688855040.0f;\n        }\n        _3685 = _3698;\n    }\n    float ty = _3685;\n    float _3714;\n    if (_3648 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3714 = (1.0f - _3634) / _3648;\n    }\n    else\n    {\n        float _3727;\n        if (_3648 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3727 = ((-1.0f) - _3634) / _3648;\n        }\n        else\n        {\n            _3727 = 1000000015047466219876688855040.0f;\n        }\n        _3714 = _3727;\n    }\n    float _3739 = tx;\n    float _3742 = (_3739 > 0.0f) ? _3739 : 1000000015047466219876688855040.0f;\n    tx = _3742;\n    float _3743 = ty;\n    float _3746 = (_3743 > 0.0f) ? _3743 : 1000000015047466219876688855040.0f;\n    ty = _3746;\n    float _3756 = min(_3742, min(_3746, (_3714 > 0.0f) ? _3714 : 1000000015047466219876688855040.0f));\n    if (_3756 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3772 = (fa_world_pos + (d * _3756)) - posw.xyz;\n    float3 _3777;\n    if (dot(_3772, _3772) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3777 = normalize(_3772);\n    }\n    else\n    {\n        _3777 = d;\n    }\n    return _3777;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3823 = (1.0f - _602_fa_rpa_tile.w) - _602_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3823 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_602_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _602_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3852 = rough * rough;\n            float _3883 = 0.60000002384185791015625f * _3852;\n            base = lerp(lerp(_602_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_602_fa_env_horizon.xyz, _602_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3852)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3883, 0.0500000007450580596923828125f + _3883, d.y).xxx), ((_602_fa_env_sky.xyz + _602_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3852 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3823;\n    }\n    if (_602_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _602_fa_rpa_tile;\n        float4 param_5 = _602_fa_rpa_pos;\n        float4 param_6 = _602_fa_rpa_bx;\n        float4 param_7 = _602_fa_rpa_by;\n        float4 param_8 = _602_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3942 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3942 * _602_fa_rpa_tile.w);\n    }\n    if (_602_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _602_fa_rpb_tile;\n        float4 param_12 = _602_fa_rpb_pos;\n        float4 param_13 = _602_fa_rpb_bx;\n        float4 param_14 = _602_fa_rpb_by;\n        float4 param_15 = _602_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3974 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3974 * _602_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4620;\n        if (L.aniso >= 0.0f)\n        {\n            _4620 = L.b;\n        }\n        else\n        {\n            _4620 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4620, v), _4620), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4653 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4653.x) + (L.f90.xxx * _4653.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4708 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4708.x) + _4708.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4185 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4185.x) + _4185.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2269_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3205 = int(_2269_fa_shadow_cfg.x + 0.5f);\n    float _3215 = dot(world - _2269_fa_shadow_eye.xyz, _2269_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3220 = _3205 > 0;\n    bool _3229;\n    if (_3220)\n    {\n        int param = _3205 - 1;\n        _3229 = _3215 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3229 = _3220;\n    }\n    if (_3229)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3235 = _3205 > 1;\n        bool _3242;\n        if (_3235)\n        {\n            _3242 = _3215 > _2269_fa_shadow_split.x;\n        }\n        else\n        {\n            _3242 = _3235;\n        }\n        if (_3242)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3248 = _3205 > 2;\n        bool _3255;\n        if (_3248)\n        {\n            _3255 = _3215 > _2269_fa_shadow_split.y;\n        }\n        else\n        {\n            _3255 = _3248;\n        }\n        if (_3255)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3261 = _3205 > 3;\n        bool _3268;\n        if (_3261)\n        {\n            _3268 = _3215 > _2269_fa_shadow_split.z;\n        }\n        else\n        {\n            _3268 = _3261;\n        }\n        if (_3268)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _7524 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7524 = -_7524;\n    }\n    float3 _6884 = normalize(_602_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _7537 = { fa_world_pos, _7524, fa_world_tangent, fa_uv, fa_vertex_color, _6884, gl_FrontFacing };\n    SurfaceInput param_1 = _7537;\n    Surface _6892 = fa_standard_surface(param_1);\n    float3 _7555 = _6892.albedo;\n    float _7556 = _6892.alpha;\n    float3 _7557 = _6892.normal;\n    float _7558 = _6892.metallic;\n    float _7559 = _6892.roughness;\n    float _7560 = _6892.occlusion;\n    float3 _7561 = _6892.emission;\n    float _7562 = _6892.clearcoat;\n    float _7563 = _6892.clearcoat_roughness;\n    float3 _7564 = _6892.sheen_color;\n    float _7565 = _6892.sheen_roughness;\n    float _7566 = _6892.anisotropy;\n    float _7567 = _6892.anisotropy_rotation;\n    float _7568 = _6892.specular;\n    float _7569 = _6892.ior;\n    float3 _7570 = _6892.specular_color;\n    SurfaceInput _7545 = { fa_world_pos, _7524, fa_world_tangent, fa_uv, fa_vertex_color, _6884, gl_FrontFacing };\n    SurfaceInput param_2 = _7545;\n    Surface param_3 = _6892;\n    surface(param_2, param_3);\n    _7555 = param_3.albedo;\n    _7556 = param_3.alpha;\n    _7557 = param_3.normal;\n    _7558 = param_3.metallic;\n    _7559 = param_3.roughness;\n    _7560 = param_3.occlusion;\n    _7561 = param_3.emission;\n    _7562 = param_3.clearcoat;\n    _7563 = param_3.clearcoat_roughness;\n    _7564 = param_3.sheen_color;\n    _7565 = param_3.sheen_roughness;\n    _7566 = param_3.anisotropy;\n    _7567 = param_3.anisotropy_rotation;\n    _7568 = param_3.specular;\n    _7569 = param_3.ior;\n    _7570 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _7524;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7555 = param_6;\n    _7557 = param_7;\n    float3 result;\n    if (_602_fa_emissive.w > 0.5f)\n    {\n        result = _7555;\n    }\n    else\n    {\n        float3 _6931 = normalize(_7557);\n        float _6938 = clamp(_7558, 0.0f, 1.0f);\n        float _6942 = clamp(_7559, 0.0500000007450580596923828125f, 1.0f);\n        float _6946 = _6942 * _6942;\n        float _6950 = _6946 * _6946;\n        float _6955 = max(dot(_6931, _6884), 9.9999997473787516355514526367188e-05f);\n        float3 _6961 = _7555 * (1.0f - _6938);\n        float3 _6968 = lerp(0.039999999105930328369140625f.xxx, _7555, _6938.xxx);\n        float3 f0 = _6968;\n        SurfaceInput _7553 = { fa_world_pos, _7524, fa_world_tangent, fa_uv, fa_vertex_color, _6884, gl_FrontFacing };\n        SurfaceInput param_8 = _7553;\n        Surface _7636 = { _7555, _7556, _7557, _7558, _7559, _7560, _7561, _7562, _7563, _7564, _7565, _7566, _7567, _7568, _7569, _7570 };\n        Surface param_9 = _7636;\n        float3 param_10 = _6931;\n        float3 param_11 = _6884;\n        float param_12 = _6938;\n        float param_13 = _6942;\n        float3 param_14 = _6968;\n        FaLayers _6984 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6931;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6961) * _7560;\n        if (_6984.on)\n        {\n            lit *= _6984.base_scale;\n        }\n        int _7006 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7006; ln++)\n        {\n            int param_16 = ln;\n            int _7019 = fa_cl_light(param_16);\n            int param_17 = _7019;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _7019;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _7524;\n            LightSample _7035 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7043 = max(dot(_6931, _7035.direction), 0.0f);\n            float _7049 = _7035.attenuation * _7035.shadow;\n            float3 _7054 = normalize(_7035.direction + _6884);\n            float _7059 = max(dot(_6931, _7054), 0.0f);\n            float _7064 = max(dot(_6884, _7054), 0.0f);\n            bool _7071;\n            if (fa_light_is_area)\n            {\n                _7071 = !_6984.on;\n            }\n            else\n            {\n                _7071 = fa_light_is_area;\n            }\n            if (_7071)\n            {\n                int param_21 = _7019;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6931;\n                float3 param_24 = _6884;\n                float3 param_25 = _6961;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6942;\n                float param_29 = _6955;\n                float param_30 = _7049;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6984;\n                    int param_32 = _7019;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6931;\n                    float3 param_35 = _6884;\n                    float3 param_36 = _7035.direction;\n                    float3 param_37 = _6961;\n                    float3 param_38 = f0;\n                    float param_39 = _6942;\n                    float param_40 = _6955;\n                    float param_41 = _7049;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6984.on)\n                    {\n                        FaLayers param_42 = _6984;\n                        float3 param_43 = _6961;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6931;\n                        float3 param_46 = _6884;\n                        float3 param_47 = _7035.direction;\n                        float3 param_48 = _7054;\n                        float param_49 = _7043;\n                        float param_50 = _6955;\n                        float param_51 = _7059;\n                        float param_52 = _7064;\n                        float param_53 = _6946;\n                        float param_54 = _6950;\n                        int param_55 = _7019;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7049));\n                    }\n                    else\n                    {\n                        float _7177 = ((_7059 * _7059) * (_6950 - 1.0f)) + 1.0f;\n                        int param_56 = _7019;\n                        lit += (((_6961 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _7064, 5.0f))) * (((_6950 / ((3.1415927410125732421875f * _7177) * _7177)) * (0.5f / max(lerp((2.0f * _7043) * _6955, _7043 + _6955, _6946), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _7043))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7043 * _7049));\n                    }\n                }\n            }\n        }\n        if (_6984.on)\n        {\n            FaLayers param_57 = _6984;\n            float3 param_58 = _6931;\n            float3 param_59 = _6884;\n            float3 param_60 = f0;\n            float param_61 = _6942;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7560);\n        }\n        else\n        {\n            float3 param_62 = _6931;\n            float3 param_63 = _6884;\n            float3 param_64 = f0;\n            float param_65 = _6942;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7560);\n        }\n        result = lit;\n    }\n    float3 _7272 = result;\n    float3 _7273 = _7272 + _7561;\n    result = _7273;\n    float3 param_66 = _7273;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _7282 = _602_fa_fog.w > 0.0f;\n    bool _7289;\n    if (!_7282)\n    {\n        _7289 = _602_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7289 = _7282;\n    }\n    if (_7289)\n    {\n        float3 _7298 = fa_world_pos - _602_fa_camera_pos.xyz;\n        float _7304 = dot(_7298, _602_fa_fog_c.xyz);\n        bool _7308 = _602_fa_fog_c.w > 0.5f;\n        float _7309;\n        if (_7308)\n        {\n            _7309 = _7304;\n        }\n        else\n        {\n            _7309 = length(_7298);\n        }\n        float _7321 = _7309 - _602_fa_fog_b.x;\n        if (_7321 > 0.0f)\n        {\n            float _7330 = _602_fa_fog.w * _7321;\n            float tau = _7330 * _7330;\n            if (_602_fa_fog_b.y > 0.0f)\n            {\n                float _7346;\n                if (_7308)\n                {\n                    _7346 = fa_world_pos.y - (_602_fa_fog_c.y * _7304);\n                }\n                else\n                {\n                    _7346 = _602_fa_camera_pos.y;\n                }\n                float _7367 = lerp(_7346, fa_world_pos.y, clamp(_602_fa_fog_b.x / _7309, 0.0f, 1.0f));\n                float _7371 = fa_world_pos.y - _7367;\n                float _7376 = _7367 - _602_fa_fog_b.z;\n                float _7381 = fa_world_pos.y - _602_fa_fog_b.z;\n                bool _7384 = _7376 <= 0.0f;\n                bool _7385 = !_7384;\n                bool _7391;\n                if (_7385)\n                {\n                    _7391 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7391 = _7384;\n                }\n                float _7392;\n                if (_7391)\n                {\n                    _7392 = _602_fa_fog_b.y;\n                }\n                else\n                {\n                    _7392 = _602_fa_fog_b.y * exp(-min(_602_fa_fog_b.w * _7376, 80.0f));\n                }\n                bool _7419;\n                if (_7385)\n                {\n                    _7419 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7419 = _7384;\n                }\n                float _7420;\n                if (_7419)\n                {\n                    _7420 = _602_fa_fog_b.y * _7376;\n                }\n                else\n                {\n                    _7420 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _7376, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                bool _7445 = _7381 <= 0.0f;\n                bool _7452;\n                if (!_7445)\n                {\n                    _7452 = _602_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7452 = _7445;\n                }\n                float _7453;\n                if (_7452)\n                {\n                    _7453 = _602_fa_fog_b.y * _7381;\n                }\n                else\n                {\n                    _7453 = (_602_fa_fog_b.y * (1.0f - exp(-min(_602_fa_fog_b.w * _7381, 80.0f)))) / _602_fa_fog_b.w;\n                }\n                float _7480;\n                if (abs(_7371) < 0.001000000047497451305389404296875f)\n                {\n                    _7480 = _7392;\n                }\n                else\n                {\n                    _7480 = (_7453 - _7420) / _7371;\n                }\n                tau += (_7321 * max(_7480, 0.0f));\n            }\n            result = lerp(result, _602_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _7556);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_602",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2269",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 11
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _45_offset : packoffset(c0);\n    float _45_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _145_fa_view_proj : packoffset(c0);\n    row_major float4x4 _145_fa_light_vp : packoffset(c4);\n    float4 _145_fa_uv_scale : packoffset(c8);\n    float4 _145_fa_time : packoffset(c9);\n    float4 _145_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _310 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145_fa_uv_scale.xy, color, position };\n    return _310;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _45_offset;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _189 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_189, _145_fa_light_vp).z;\n    fa_pre_r0 = float3(_145_fa_light_vp[0].x, _145_fa_light_vp[1].x, _145_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_145_fa_light_vp[0].y, _145_fa_light_vp[1].y, _145_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_145_fa_light_vp[0].z, _145_fa_light_vp[1].z, _145_fa_light_vp[2].z);\n    gl_Position = mul(_189, _145_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n    float4 _215_fa_atlas : packoffset(c39);\n    float4 _215_fa_rpa_tile : packoffset(c40);\n    float4 _215_fa_rpa_pos : packoffset(c41);\n    float4 _215_fa_rpa_bx : packoffset(c42);\n    float4 _215_fa_rpa_by : packoffset(c43);\n    float4 _215_fa_rpa_bz : packoffset(c44);\n    float4 _215_fa_rpb_tile : packoffset(c45);\n    float4 _215_fa_rpb_pos : packoffset(c46);\n    float4 _215_fa_rpb_bx : packoffset(c47);\n    float4 _215_fa_rpb_by : packoffset(c48);\n    float4 _215_fa_rpb_bz : packoffset(c49);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _738 = base_t;\n    _738.x = _227.x;\n    _738.y = _227.y;\n    _738.z = _227.z;\n    base_t = _738;\n    float4 _243 = (_738 * _215_fa_base_color) * i.vertex_color;\n    float3 _701 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _746 = _281;\n        _746.x = _286.x;\n        _746.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _746;\n        _701 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _749 = mrt;\n    _749.x = _315.x;\n    _749.y = _315.y;\n    _749.z = _315.z;\n    mrt = _749;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _706 = _215_fa_layers_a.x;\n    float _707 = _215_fa_layers_a.y;\n    float _710 = _215_fa_layers_a.z;\n    float _709 = _215_fa_layers_b.w;\n    float _712 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _706 *= _357.y;\n            _707 *= _357.z;\n            _709 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _710 *= mrt.x;\n            _712 *= mrt.w;\n        }\n    }\n    Surface _731 = { _243.xyz, _243.w, _701, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _706, _707, _215_fa_layers_b.xyz, _709, _710, _215_fa_layers_a.w, _712, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _731;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _612 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _612 = -_612;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _625 = { fa_world_pos, _612, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _625;\n    SurfaceInput _633 = { fa_world_pos, _612, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _633;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 800,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _50_offset : packoffset(c0);\n    float _50_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _150_fa_view_proj : packoffset(c0);\n    row_major float4x4 _150_fa_light_vp : packoffset(c4);\n    float4 _150_fa_uv_scale : packoffset(c8);\n    float4 _150_fa_time : packoffset(c9);\n    float4 _150_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _197_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_197_fa_joint_rows[_188] * weights[i]);\n        r1 += (_197_fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197_fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _431 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150_fa_uv_scale.xy, color, position };\n    return _431;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _50_offset;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _302 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_302, _150_fa_light_vp).z;\n    fa_pre_r0 = float3(_150_fa_light_vp[0].x, _150_fa_light_vp[1].x, _150_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_150_fa_light_vp[0].y, _150_fa_light_vp[1].y, _150_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_150_fa_light_vp[0].z, _150_fa_light_vp[1].z, _150_fa_light_vp[2].z);\n    gl_Position = mul(_302, _150_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n    float4 _215_fa_atlas : packoffset(c39);\n    float4 _215_fa_rpa_tile : packoffset(c40);\n    float4 _215_fa_rpa_pos : packoffset(c41);\n    float4 _215_fa_rpa_bx : packoffset(c42);\n    float4 _215_fa_rpa_by : packoffset(c43);\n    float4 _215_fa_rpa_bz : packoffset(c44);\n    float4 _215_fa_rpb_tile : packoffset(c45);\n    float4 _215_fa_rpb_pos : packoffset(c46);\n    float4 _215_fa_rpb_bx : packoffset(c47);\n    float4 _215_fa_rpb_by : packoffset(c48);\n    float4 _215_fa_rpb_bz : packoffset(c49);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _738 = base_t;\n    _738.x = _227.x;\n    _738.y = _227.y;\n    _738.z = _227.z;\n    base_t = _738;\n    float4 _243 = (_738 * _215_fa_base_color) * i.vertex_color;\n    float3 _701 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _746 = _281;\n        _746.x = _286.x;\n        _746.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _746;\n        _701 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _749 = mrt;\n    _749.x = _315.x;\n    _749.y = _315.y;\n    _749.z = _315.z;\n    mrt = _749;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _706 = _215_fa_layers_a.x;\n    float _707 = _215_fa_layers_a.y;\n    float _710 = _215_fa_layers_a.z;\n    float _709 = _215_fa_layers_b.w;\n    float _712 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _706 *= _357.y;\n            _707 *= _357.z;\n            _709 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _710 *= mrt.x;\n            _712 *= mrt.w;\n        }\n    }\n    Surface _731 = { _243.xyz, _243.w, _701, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _706, _707, _215_fa_layers_b.xyz, _709, _710, _215_fa_layers_a.w, _712, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _731;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _612 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _612 = -_612;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _625 = { fa_world_pos, _612, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _625;\n    SurfaceInput _633 = { fa_world_pos, _612, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _633;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 800,
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
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _36_offset : packoffset(c0);\n    float _36_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _262 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _262;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _36_offset;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _136_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_36",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _41_offset : packoffset(c0);\n    float _41_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _141_fa_view_proj : packoffset(c0);\n    row_major float4x4 _141_fa_light_vp : packoffset(c4);\n    float4 _141_fa_uv_scale : packoffset(c8);\n    float4 _141_fa_time : packoffset(c9);\n    float4 _141_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _188_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _179 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_188_fa_joint_rows[_179] * weights[i]);\n        r1 += (_188_fa_joint_rows[_179 + 1] * weights[i]);\n        r2 += (_188_fa_joint_rows[_179 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _383 = { mul(float4(position, 1.0f), model).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _141_fa_uv_scale.xy, color, position };\n    return _383;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _41_offset;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _141_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_188",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
