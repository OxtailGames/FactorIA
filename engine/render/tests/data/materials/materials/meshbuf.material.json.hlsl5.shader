{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4155841b00106f1351e36fe7e96d502ece90660dd797ea3c7df876d511a0f129",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _168_fa_view_proj : packoffset(c0);\n    row_major float4x4 _168_fa_light_vp : packoffset(c4);\n    float4 _168_fa_uv_scale : packoffset(c8);\n    float4 _168_fa_time : packoffset(c9);\n    float4 _168_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _238_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _279 = { mul(float4(position, 1.0f), model).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168_fa_uv_scale.xy, color, position };\n    return _279;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _168_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _238_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _3692[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _595_fa_camera_pos : packoffset(c0);\n    float4 _595_fa_ambient : packoffset(c1);\n    float4 _595_fa_base_color : packoffset(c2);\n    float4 _595_fa_emissive : packoffset(c3);\n    float4 _595_fa_model_emissive : packoffset(c4);\n    float4 _595_fa_pbr : packoffset(c5);\n    float4 _595_fa_maps : packoffset(c6);\n    float4 _595_fa_fog : packoffset(c7);\n    float4 _595_fa_fog_b : packoffset(c8);\n    float4 _595_fa_fog_c : packoffset(c9);\n    float4 _595_fa_counts : packoffset(c10);\n    float4 _595_fa_env_sky : packoffset(c11);\n    float4 _595_fa_env_horizon : packoffset(c12);\n    float4 _595_fa_time : packoffset(c13);\n    float4 _595_fa_cl_vpx : packoffset(c14);\n    float4 _595_fa_cl_vpy : packoffset(c15);\n    float4 _595_fa_cl_vpw : packoffset(c16);\n    float4 _595_fa_cl_fwd : packoffset(c17);\n    float4 _595_fa_cl_grid : packoffset(c18);\n    float4 _595_fa_cl_info : packoffset(c19);\n    float4 _595_fa_layers_a : packoffset(c20);\n    float4 _595_fa_layers_b : packoffset(c21);\n    float4 _595_fa_layers_c : packoffset(c22);\n    float4 _595_fa_layers_d : packoffset(c23);\n    float4 _595_fa_ct_a : packoffset(c24);\n    float4 _595_fa_ct_b : packoffset(c25);\n    float4 _595_fa_ct_vpx : packoffset(c26);\n    float4 _595_fa_ct_vpy : packoffset(c27);\n    float4 _595_fa_ct_vpw : packoffset(c28);\n    float4 _595_fa_ct_fwd : packoffset(c29);\n    float4 _595_fa_tr_a : packoffset(c30);\n    float4 _595_fa_tr_b : packoffset(c31);\n    float4 _595_fa_probe_sh[9] : packoffset(c32);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2262_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2262_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2262_fa_shadow_info[4] : packoffset(c20);\n    float4 _2262_fa_shadow_split : packoffset(c24);\n    float4 _2262_fa_shadow_cfg : packoffset(c25);\n    float4 _2262_fa_shadow_bias : packoffset(c26);\n    float4 _2262_fa_shadow_eye : packoffset(c27);\n    float4 _2262_fa_shadow_fwd : packoffset(c28);\n    float4 _2262_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1533 = _595_fa_cl_info.x < 0.0f;\n    bool _1540;\n    if (!_1533)\n    {\n        _1540 = _595_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1540 = _1533;\n    }\n    bool _1548;\n    if (!_1540)\n    {\n        _1548 = _595_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1548 = _1540;\n    }\n    bool _1555;\n    if (!_1548)\n    {\n        _1555 = _595_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1555 = _1548;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = _595_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    if (_1562)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1572 = float4(world_pos, 1.0f);\n    float _1578 = dot(_595_fa_cl_vpw, _1572);\n    if (!(_1578 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1600 = float2(dot(_595_fa_cl_vpx, _1572), dot(_595_fa_cl_vpy, _1572)) / _1578.xx;\n    int _1604 = int(_595_fa_cl_grid.x);\n    int _1608 = int(_595_fa_cl_grid.y);\n    int param = (int(_595_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_595_fa_cl_fwd.xyz, world_pos) + _595_fa_cl_fwd.w, _595_fa_cl_grid.w) / _595_fa_cl_grid.w) * _595_fa_cl_grid.z)), 0, int(_595_fa_cl_info.y) - 1) * _1608) + clamp(int(floor(((_1600.y * 0.5f) + 0.5f) * _595_fa_cl_grid.y)), 0, _1608 - 1)) * _1604)) + clamp(int(floor(((_1600.x * 0.5f) + 0.5f) * _595_fa_cl_grid.x)), 0, _1604 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1684 = fa_cluster_texel(param);\n    return int2(int(_1684.x), int(_1684.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_595_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5153 = fa_cluster_lookup(param);\n    fa_cl_slot = _5153.x;\n    fa_cl_local = _5153.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6301 = fa_linear_to_srgb(param);\n        c = _6301;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6309 = fa_srgb_to_linear(param_1);\n            c = _6309;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _477;\n    if (i.front_facing)\n    {\n        _477 = i.world_normal;\n    }\n    else\n    {\n        _477 = -i.world_normal;\n    }\n    float3 _501 = normalize(i.world_tangent.xyz - (_477 * dot(_477, i.world_tangent.xyz)));\n    float3 _528 = normalize(((_501 * m.x) + ((cross(_477, _501) * i.world_tangent.w) * m.y)) + (_477 * m.z));\n    float3 _531;\n    if (i.front_facing)\n    {\n        _531 = _528;\n    }\n    else\n    {\n        _531 = -_528;\n    }\n    return _531;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _595_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6340 = fa_tex_fix(param_2, param_3);\n    float4 _7938 = base_t;\n    _7938.x = _6340.x;\n    _7938.y = _6340.y;\n    _7938.z = _6340.z;\n    base_t = _7938;\n    float4 _6354 = (_7938 * _595_fa_base_color) * i.vertex_color;\n    float3 _7747 = i.world_normal;\n    if (_595_fa_maps.z > 0.5f)\n    {\n        float param_4 = _595_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6386 = fa_tex_fix(param_6, param_7);\n        float3 _6389 = (_6386 * 2.0f) - 1.0f.xxx;\n        float2 _6394 = _6389.xy * _595_fa_maps.x;\n        float3 _7946 = _6389;\n        _7946.x = _6394.x;\n        _7946.y = _6394.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7946;\n        _7747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _595_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6422 = fa_tex_fix(param_12, param_13);\n    float4 _7949 = mrt;\n    _7949.x = _6422.x;\n    _7949.y = _6422.y;\n    _7949.z = _6422.z;\n    mrt = _7949;\n    float4 _6450 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _595_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6450.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6461 = fa_tex_fix(param_16, param_17);\n    float param_18 = _595_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6491 = fa_tex_fix(param_20, param_21);\n    float _7752 = _595_fa_layers_a.x;\n    float _7753 = _595_fa_layers_a.y;\n    float _7756 = _595_fa_layers_a.z;\n    float _7755 = _595_fa_layers_b.w;\n    float _7758 = _595_fa_layers_c.x;\n    if (_595_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_595_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7752 *= _6461.y;\n            _7753 *= _6461.z;\n            _7755 *= _6450.w;\n        }\n        if (_595_fa_layers_c.z > 1.5f)\n        {\n            _7756 *= mrt.x;\n            _7758 *= mrt.w;\n        }\n    }\n    Surface _7785 = { _6354.xyz, _6354.w, _7747, clamp(_595_fa_pbr.x * _6422.z, 0.0f, 1.0f), clamp(_595_fa_pbr.y * _6422.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_595_fa_maps.y * (_6461.x - 1.0f)), _595_fa_emissive.xyz + (_595_fa_model_emissive.xyz * _6491), _7752, _7753, _595_fa_layers_b.xyz, _7755, _7756, _595_fa_layers_a.w, _7758, _595_fa_layers_c.y, _595_fa_layers_d.xyz, _595_fa_tr_a.x, _595_fa_tr_a.y, _595_fa_tr_b.xyz, _595_fa_tr_a.z };\n    return _7785;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1764 = rect.zw - rect.xy;\n    float2 _1768 = _1764 * atlas;\n    float2 _1772 = ddx * _1768;\n    float2 _1776 = ddy * _1768;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1764), clamp(0.5f * log2(max(max(dot(_1772, _1772), dot(_1776, _1776)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1809 = _595_fa_counts.y < 0.5f;\n    bool _1816;\n    if (!_1809)\n    {\n        _1816 = _595_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1816 = _1809;\n    }\n    if (_1816)\n    {\n        return;\n    }\n    float3 _1822 = ddx(world_pos);\n    float3 _1825 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1829 = fa_cluster_texel(param);\n    int _1833 = int(_1829.w);\n    if (_1833 < 1)\n    {\n        return;\n    }\n    int _1843 = int(_595_fa_counts.y + 0.5f);\n    int param_1 = _1843;\n    float4 _1847 = fa_light_texel(param_1);\n    float2 _1850 = _1847.yz;\n    int _1854 = int(_1847.w);\n    int param_2 = _1843 + 1;\n    float4 _1859 = fa_light_texel(param_2);\n    float _1860 = _1859.x;\n    int _1866 = int(_595_fa_counts.w + 0.5f) - 1;\n    int _1870 = int(_1829.z);\n    float3 _2135;\n    for (int k = 0; k < _1833; k++)\n    {\n        int _1883 = _1870 + k;\n        int param_3 = _1854 + (_1883 >> 2);\n        int _1900 = (_1843 + 2) + (int(fa_light_texel(param_3)[_1883 & 3]) * 7);\n        int param_4 = _1900 + 6;\n        float4 _1905 = fa_light_texel(param_4);\n        if (((int(_1905.w + 0.5f) >> _1866) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1900;\n        float4 _1920 = fa_light_texel(param_5);\n        int param_6 = _1900 + 1;\n        float4 _1925 = fa_light_texel(param_6);\n        int param_7 = _1900 + 2;\n        float4 _1930 = fa_light_texel(param_7);\n        float3 _1933 = _1920.xyz;\n        float _1938 = dot(_1933, world_pos) + _1920.w;\n        float3 _1940 = _1925.xyz;\n        float _1945 = dot(_1940, world_pos) + _1925.w;\n        float3 _1947 = _1930.xyz;\n        float _1952 = dot(_1947, world_pos) + _1930.w;\n        bool _1957 = abs(_1938) > 0.5f;\n        bool _1965;\n        if (!_1957)\n        {\n            _1965 = abs(_1945) > 0.5f;\n        }\n        else\n        {\n            _1965 = _1957;\n        }\n        bool _1973;\n        if (!_1965)\n        {\n            _1973 = abs(_1952) > 0.5f;\n        }\n        else\n        {\n            _1973 = _1965;\n        }\n        if (_1973)\n        {\n            continue;\n        }\n        float _1988 = clamp(dot(geo_normal, normalize(_1947)) * _1905.z, 0.0f, 1.0f);\n        if (_1988 <= 0.0f)\n        {\n            continue;\n        }\n        float _2008 = (clamp((0.5f - abs(_1952)) * 10.0f, 0.0f, 1.0f) * _1988) * _1905.x;\n        float2 _2016 = float2(_1938 + 0.5f, 0.5f - _1945);\n        float2 _2026 = float2(dot(_1933, _1822), dot(_1940, _1822));\n        float2 _2036 = float2(dot(_1933, _1825), dot(_1940, _1825));\n        int param_8 = _1900 + 5;\n        float4 _2041 = fa_light_texel(param_8);\n        int param_9 = _1900 + 3;\n        float4 _2046 = fa_light_texel(param_9);\n        int param_10 = _1900 + 4;\n        float4 _2051 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2041.xyz;\n        bool _2061 = _2046.z > _2046.x;\n        if (_2061)\n        {\n            float4 param_11 = _2046;\n            float2 param_12 = _2016;\n            float2 param_13 = _1850;\n            float2 param_14 = _2026;\n            float2 param_15 = _2036;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1860 > 0.5f) && (_1860 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2087 = fa_dc_to_linear(param_16);\n                float4 _7835 = tx;\n                _7835.x = _2087.x;\n                _7835.y = _2087.y;\n                _7835.z = _2087.z;\n                tx = _7835;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2008 * tex_a) * _2041.w, 0.0f, 1.0f).xxx);\n        if (_2051.z > _2051.x)\n        {\n            float4 param_17 = _2051;\n            float2 param_18 = _2016;\n            float2 param_19 = _1850;\n            float2 param_20 = _2026;\n            float2 param_21 = _2036;\n            float4 _2131 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1860 > 1.5f)\n            {\n                float3 param_22 = _2131.xyz;\n                float3 _2141 = fa_dc_to_srgb(param_22);\n                _2135 = _2141;\n            }\n            else\n            {\n                _2135 = _2131.xyz;\n            }\n            float3 _2150 = (_2135 * 2.0f) - 1.0f.xxx;\n            float2 _2155 = _2150.xy * _1905.y;\n            float3 _2177 = (normalize(_1933) * _2155.x) + (normalize(_1940) * _2155.y);\n            float3 _2180 = normalize(normal);\n            normal = normalize(lerp(_2180, normalize((_2180 * max(_2150.z, 0.0500000007450580596923828125f)) + (_2177 - (_2180 * dot(_2180, _2177)))), clamp(_2008 * (_2061 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3618 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3625 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3628 = int(_3618);\n    int _3631 = int(_3625);\n    float _3641 = _3625 - float(_3631);\n    int _3696 = (_3628 * 9) + _3631;\n    int _3716 = ((_3628 + 1) * 9) + _3631;\n    return lerp(lerp(_3692[_3696], _3692[_3696 + 1], _3641), lerp(_3692[_3716], _3692[_3716 + 1], _3641), _3618 - float(_3628));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7670 = false;\n    float _7671 = 1.0f;\n    float _7672 = 1.0f;\n    float _7673 = 1.0f;\n    float _7674 = 0.0f;\n    float _7675 = 0.0f;\n    float _7676 = 0.0f;\n    float _7677 = 0.0f;\n    float _7679 = 1.0f;\n    bool _7680 = false;\n    float3 _7681 = 0.0f.xxx;\n    float _7682 = 1.0f;\n    float _7683 = 1.0f;\n    float _7684 = 1.0f;\n    float _7685 = 0.0f;\n    float _7686 = 0.0f;\n    float3 _7687 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7688 = float3(0.0f, 0.0f, 1.0f);\n    float _7689 = 1.0f;\n    float _7690 = 1.0f;\n    float _3767 = clamp(s.specular, 0.0f, 1.0f);\n    float _3771 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3776 = (_3767 != 1.0f) || (_3771 != 1.5f);\n    bool _3785;\n    if (!_3776)\n    {\n        _3785 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3785 = _3776;\n    }\n    if (_3785)\n    {\n        float _3793 = (_3771 - 1.0f) / (_3771 + 1.0f);\n        f0 = lerp(min((_3793 * _3793).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3767, s.albedo, metallic.xxx);\n        _7671 = lerp(_3767, 1.0f, metallic);\n        _7670 = true;\n    }\n    float _3820 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3820 > 0.0f)\n    {\n        float _3828 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7674 = _3820;\n        _7675 = _3828;\n        float _3835 = _3828 * _3828;\n        _7676 = _3835;\n        _7677 = _3835 * _3835;\n        float _3847 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7679 = _3847;\n        _7672 = 1.0f - (_3820 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3847, 0.0f, 1.0f), 5.0f))));\n        _7670 = true;\n    }\n    float3 _3866 = max(s.sheen_color, 0.0f.xxx);\n    float _3875 = max(_3866.x, max(_3866.y, _3866.z));\n    if (_3875 > 0.0f)\n    {\n        float _3883 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7680 = true;\n        _7681 = _3866;\n        _7682 = _3883;\n        _7683 = _3883 * _3883;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3883;\n        float _3900 = fa_sheen_albedo(param, param_1);\n        _7685 = _3900;\n        _7684 = 1.0f - min(_3875 * _3900, 1.0f);\n        _7670 = true;\n    }\n    _7673 = _7672 * _7684;\n    float _3919 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3919 != 0.0f)\n    {\n        float3 _3934 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3934;\n        if (dot(_3934, _3934) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3946 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3946.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3946.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3946.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3950 = t;\n        float3 _3951 = normalize(_3950);\n        t = _3951;\n        float3 _3976 = normalize((_3951 * cos(s.anisotropy_rotation)) + ((cross(n, _3951) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7687 = _3976;\n        _7688 = cross(n, _3976);\n        float _3986 = roughness * roughness;\n        float _3992 = lerp(_3986, 1.0f, _3919 * _3919);\n        bool _3994 = _3919 > 0.0f;\n        _7689 = _3994 ? _3992 : _3986;\n        _7690 = _3994 ? _3986 : _3992;\n        _7686 = _3919;\n        _7670 = true;\n    }\n    FaLayers _7712 = { _7670, _7671, _7672, _7673, _7674, _7675, _7676, _7677, i.world_normal, _7679, _7680, _7681, _7682, _7683, _7684, _7685, _7686, _7687, _7688, _7689, _7690 };\n    return _7712;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_595_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3375 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3375;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_595_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _595_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_595_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _595_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_595_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_595_fa_cl_info.x) + int(_595_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_595_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5123;\n    if (fa_lm.z > 0.5f)\n    {\n        _5123 = 0.0f;\n    }\n    else\n    {\n        _5123 = 1.0f - clamp(_595_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5134 = _5123 < 1.0f;\n    bool _5140;\n    if (_5134)\n    {\n        int param = li;\n        _5140 = fa_light_baked(param);\n    }\n    else\n    {\n        _5140 = _5134;\n    }\n    return _5140 ? _5123 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _663_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _663_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _782 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _795 = (c - (ru * hx)) - p;\n        float3 _801 = ru * (2.0f * hx);\n        float _807 = max(dot(_801, _801), 9.9999999392252902907785028219223e-09f);\n        float _811 = dot(_795, _801);\n        float t = clamp((-_811) / _807, 0.0f, 1.0f);\n        if (_782)\n        {\n            float _826 = dot(r, _801);\n            float _832 = _807 - (_826 * _826);\n            if (abs(_832) > (9.9999997473787516355514526367188e-06f * _807))\n            {\n                t = clamp(((dot(r, _795) * _826) - _811) / _832, 0.0f, 1.0f);\n            }\n        }\n        return (p + _795) + (_801 * t);\n    }\n    float3 q = p;\n    float _864 = dot(r, axis);\n    bool _872;\n    if (_782)\n    {\n        _872 = abs(_864) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _872 = _782;\n    }\n    if (_872)\n    {\n        float _882 = dot(c - p, axis) / _864;\n        if (_882 > 0.0f)\n        {\n            q = p + (r * _882);\n        }\n    }\n    float3 _895 = q - c;\n    float2 xy = float2(dot(_895, ru), dot(_895, uu));\n    if (shape > 0.5f)\n    {\n        float _910 = length(xy);\n        if (_910 > hx)\n        {\n            xy *= (hx / _910);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _543 = abs(d);\n    float _545 = _543.x;\n    float _547 = _543.y;\n    bool _548 = _545 >= _547;\n    bool _556;\n    if (_548)\n    {\n        _556 = _545 >= _543.z;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    int _557;\n    if (_556)\n    {\n        _557 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _572;\n        if (_547 >= _543.z)\n        {\n            _572 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _572 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _557 = _572;\n    }\n    return _557;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _702 = dot(d, right);\n    float _706 = dot(d, up);\n    float _717;\n    if (((_702 * _702) + (_706 * _706)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _717 = atan2(_706, _702) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _717 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_717 - floor(_717)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _948 = fa_light_base(param);\n    bool _952 = _595_fa_ambient.w > 4.5f;\n    int param_1 = _948;\n    float4 _956 = fa_light_texel(param_1);\n    int param_2 = _948 + 1;\n    float4 _961 = fa_light_texel(param_2);\n    float _964 = _961.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _976 = _952 && (_964 > 2.5f);\n    fa_light_is_area = _976;\n    bool _978 = _964 < 0.5f;\n    float3 l;\n    if (_978)\n    {\n        l = normalize(_956.xyz);\n        if (_952)\n        {\n            int param_3 = _948 + 6;\n            float4 _992 = fa_light_texel(param_3);\n            if (_992.z > 0.5f)\n            {\n                int param_4 = _948 + 4;\n                float4 _1002 = fa_light_texel(param_4);\n                int param_5 = _948 + 5;\n                float4 _1007 = fa_light_texel(param_5);\n                float2 param_6 = _992.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1002.xyz) * _1002.w, (-dot(world_pos, _1007.xyz)) * _1007.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1037 = _956.xyz;\n        float3 _1039 = _1037 - world_pos;\n        float3 to_light = _1039;\n        float _1042 = length(_1039);\n        float reach = _1042;\n        bool front = true;\n        if (_976)\n        {\n            int param_8 = _948 + 7;\n            reach = max(_1042 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _948 + 4;\n            float4 _1066 = fa_light_texel(param_9);\n            int param_10 = _948 + 5;\n            float4 _1071 = fa_light_texel(param_10);\n            int param_11 = _948 + 6;\n            float4 _1076 = fa_light_texel(param_11);\n            float _1077 = _1076.w;\n            int param_12 = _948 + 2;\n            float3 _1084 = normalize(fa_light_texel(param_12).xyz);\n            bool _1086 = _1077 > 1.5f;\n            bool _1094;\n            if (!_1086)\n            {\n                _1094 = dot(_1084, to_light) < 0.0f;\n            }\n            else\n            {\n                _1094 = _1086;\n            }\n            front = _1094;\n            float3 r = 0.0f.xxx;\n            float3 _1103 = _595_fa_camera_pos.xyz - world_pos;\n            bool _1107 = dot(n, n) > 0.5f;\n            bool _1115;\n            if (_1107)\n            {\n                _1115 = dot(_1103, _1103) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1115 = _1107;\n            }\n            if (_1115)\n            {\n                r = reflect(-normalize(_1103), normalize(n));\n            }\n            float3 param_13 = _1037;\n            float3 param_14 = _1084;\n            float3 param_15 = _1066.xyz;\n            float3 param_16 = _1071.xyz;\n            float param_17 = _1066.w;\n            float param_18 = _1071.w;\n            float param_19 = _1077;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1151 = length(to_light);\n        dist = _1151;\n        l = to_light / max(_1151, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1165 = reach / max(_956.w, 0.001000000047497451305389404296875f);\n        float _1171 = clamp(1.0f - (_1165 * _1165), 0.0f, 1.0f);\n        float _1173;\n        if (front)\n        {\n            _1173 = _1171 * _1171;\n        }\n        else\n        {\n            _1173 = 0.0f;\n        }\n        atten = _1173;\n        bool _1184 = _964 < 2.5f;\n        if ((_964 > 1.5f) && _1184)\n        {\n            int param_22 = _948 + 2;\n            float4 _1192 = fa_light_texel(param_22);\n            float _1202 = _1192.w;\n            int param_23 = _948 + 3;\n            float4 _1207 = fa_light_texel(param_23);\n            float _1208 = _1207.x;\n            float cos_inner = _1208;\n            if (_1208 > 1.5f)\n            {\n                cos_inner = lerp(_1202, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1202, cos_inner, dot(-l, normalize(_1192.xyz)));\n        }\n        if (_952 && (_964 < 1.5f))\n        {\n            int param_24 = _948 + 6;\n            float4 _1232 = fa_light_texel(param_24);\n            if (_1232.z > 0.5f)\n            {\n                float3 _1240 = -to_light;\n                int param_25 = _948 + 4;\n                int param_26 = _948 + 5;\n                float3 _1254 = fa_light_texel(param_25).xyz;\n                float3 _1258 = fa_light_texel(param_26).xyz;\n                float3 _1267 = float3(dot(_1240, _1254), dot(_1240, _1258), dot(_1240, cross(_1254, _1258)));\n                float3 param_27 = _1267;\n                int _1271 = fa_cube_face(param_27);\n                int param_28 = _1271;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1298 = float2(dot(_1267, cross(param_29, param_30)), dot(_1267, param_30)) / max(dot(_1267, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1302 = _1271 / 3;\n                float2 param_31 = _1232.xy + (float2(float(_1271 - (_1302 * 3)), float(_1302)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1298.x), 0.5f - (0.5f * _1298.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _948 + 7;\n            float4 _1332 = fa_light_texel(param_33);\n            if (_1332.z > 0.5f)\n            {\n                int param_34 = _948 + 2;\n                int param_35 = _948 + 4;\n                int param_36 = _948 + 5;\n                float2 param_37 = _1332.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_952 && _1184)\n            {\n                int param_42 = _948 + 6;\n                float4 _1379 = fa_light_texel(param_42);\n                int param_43 = _948 + 7;\n                float4 _1384 = fa_light_texel(param_43);\n                bool _1387 = _1379.z > 0.5f;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _1384.z > 0.5f;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                if (_1394)\n                {\n                    int param_44 = _948 + 2;\n                    float4 _1401 = fa_light_texel(param_44);\n                    float3 _1405 = normalize(_1401.xyz);\n                    int param_45 = _948 + 4;\n                    float4 _1410 = fa_light_texel(param_45);\n                    int param_46 = _948 + 5;\n                    float4 _1415 = fa_light_texel(param_46);\n                    if (_1387)\n                    {\n                        float3 _1423 = -to_light;\n                        float _1430 = _1401.w;\n                        float _1446 = 0.5f / max(dot(_1423, _1405) * (sqrt(max(1.0f - (_1430 * _1430), 0.0f)) / max(_1430, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1379.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1423, _1410.xyz) * _1446), 0.5f - (dot(_1423, _1415.xyz) * _1446));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1384.z > 0.5f)\n                    {\n                        float2 param_49 = _1384.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1405;\n                        float3 param_52 = _1410.xyz;\n                        float3 param_53 = _1415.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7658 = _961.xyz * atten;\n    if (_952)\n    {\n        _7658 *= fa_light_tint;\n    }\n    int _1515;\n    if (_978)\n    {\n        _1515 = 0;\n    }\n    else\n    {\n        _1515 = ((_964 > 1.5f) && (_964 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7669 = { l, _7658, atten, 1.0f, dist, _1515 };\n    return _7669;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2252;\n    if (i == 0)\n    {\n        _2252 = _2262_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2268;\n        if (i == 1)\n        {\n            _2268 = _2262_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2276;\n            if (i == 2)\n            {\n                _2276 = _2262_fa_shadow_split.z;\n            }\n            else\n            {\n                _2276 = _2262_fa_shadow_split.w;\n            }\n            _2268 = _2276;\n        }\n        _2252 = _2268;\n    }\n    return _2252;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2309 = fa_shadow_depth(param, param_1);\n    float _2313;\n    if (conv.x < 0.5f)\n    {\n        _2313 = _2309;\n    }\n    else\n    {\n        _2313 = (conv.y * conv.z) / (conv.z - (_2309 * (conv.z - conv.y)));\n    }\n    return _2313;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2240 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2240), sin(_2240)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2359 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2368;\n        if (k < 0.0f)\n        {\n            _2368 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2368 = k;\n        }\n        float _2388 = clamp((_2368 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2359;\n            float2 _2407 = fa_shadow_vogel(param_3, param_4, param_5) * _2388;\n            float2 param_6 = uv + (_2407 * _2262_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2419 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2419 < (zr - (length(_2407) * plane)))\n            {\n                sum += _2419;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2445 = sum / cnt;\n        float _2455;\n        if (k < 0.0f)\n        {\n            _2455 = (-k) / max(_2445, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2455 = k;\n        }\n        radius = clamp(((max(zr - _2445, 0.0f) * unit) * _2455) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2477 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2477; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2477;\n        float param_11 = _2359;\n        float2 _2496 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2496 * _2262_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2496) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2477);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2538 = max(_2262_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2543 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2549 = sqrt(1.0f - (_2543 * _2543));\n    float _2556 = min(_2549 / max(_2543, 0.20000000298023223876953125f), 4.0f);\n    float _2561;\n    if (_2262_fa_shadow_bias.y > 0.0f)\n    {\n        _2561 = _2262_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2561 = 1.5f * _2262_fa_shadow_info[ci].x;\n    }\n    float4 _2586 = mul(float4(world + (n * (_2561 * _2549)), 1.0f), _2262_fa_shadow_mat[ci]);\n    float _2593 = _2586.x;\n    bool _2596 = _2593 < _2262_fa_shadow_rect[ci].x;\n    bool _2605;\n    if (!_2596)\n    {\n        _2605 = _2593 > _2262_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2605 = _2596;\n    }\n    bool _2614;\n    if (!_2605)\n    {\n        _2614 = _2586.y < _2262_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2614 = _2605;\n    }\n    bool _2623;\n    if (!_2614)\n    {\n        _2623 = _2586.y > _2262_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2623 = _2614;\n    }\n    bool _2630;\n    if (!_2623)\n    {\n        _2630 = _2586.z > 1.0f;\n    }\n    else\n    {\n        _2630 = _2623;\n    }\n    if (_2630)\n    {\n        return -1.0f;\n    }\n    float _2638;\n    if (_2262_fa_shadow_bias.x > 0.0f)\n    {\n        _2638 = _2262_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2638 = 1.5f * _2262_fa_shadow_info[ci].x;\n    }\n    float2 param = _2586.xy;\n    float4 param_1 = _2262_fa_shadow_rect[ci];\n    float param_2 = _2586.z - ((_2638 * (1.0f + (0.5f * _2556))) / _2538);\n    float param_3 = _2262_fa_shadow_info[ci].x;\n    float param_4 = _2538;\n    float param_5 = _2538 * 0.25f;\n    float param_6 = ((_2262_fa_shadow_info[ci].x * min(_2556, 3.0f)) * 0.5f) / _2538;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2262_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2262_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_595_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3016 = int(_2262_fa_shadow_cfg.x + 0.5f);\n    if (_3016 < 1)\n    {\n        return 1.0f;\n    }\n    float _3031 = dot(world - _2262_fa_shadow_eye.xyz, _2262_fa_shadow_fwd.xyz);\n    int param = _3016 - 1;\n    if (_3031 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3043 = _3016 > 1;\n    bool _3050;\n    if (_3043)\n    {\n        _3050 = _3031 > _2262_fa_shadow_split.x;\n    }\n    else\n    {\n        _3050 = _3043;\n    }\n    if (_3050)\n    {\n        ci = 1;\n    }\n    bool _3054 = _3016 > 2;\n    bool _3061;\n    if (_3054)\n    {\n        _3061 = _3031 > _2262_fa_shadow_split.y;\n    }\n    else\n    {\n        _3061 = _3054;\n    }\n    if (_3061)\n    {\n        ci = 2;\n    }\n    bool _3065 = _3016 > 3;\n    bool _3072;\n    if (_3065)\n    {\n        _3072 = _3031 > _2262_fa_shadow_split.z;\n    }\n    else\n    {\n        _3072 = _3065;\n    }\n    if (_3072)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3016)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3098 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3098;\n        if (_3098 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2262_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3123;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3123 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3123 = _2262_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3142 = _2262_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3123, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3153 = clamp((_3031 - (fa_shadow_split_at(param_7) - _3142)) / _3142, 0.0f, 1.0f);\n        if (_3153 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3016)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3174 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3174;\n                if (_3174 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3153);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2696 = _595_fa_pbr.z < 0.5f;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = _2262_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2262_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2716 = fa_light_texel(param);\n    float _2717 = _2716.x;\n    if (_2717 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2726 = int(_2717 + 0.5f);\n    int param_1 = _2726;\n    float4 _2730 = fa_light_texel(param_1);\n    int param_2 = _2726 + 1;\n    float4 _2735 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2738 = _2730.y;\n    if (_2738 > 0.0f)\n    {\n        float _2755 = 1.0f - smoothstep(0.75f * _2738, _2738, length(world - _2262_fa_shadow_eye.xyz));\n        fade = _2755;\n        if (_2755 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2730.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2779 = (_2726 + 2) + (face * 6);\n    int param_4 = _2779;\n    int param_5 = _2779 + 1;\n    int param_6 = _2779 + 3;\n    float4 _2793 = fa_light_texel(param_6);\n    int param_7 = _2779 + 4;\n    float4 _2798 = fa_light_texel(param_7);\n    int param_8 = _2779 + 5;\n    float4 _2803 = fa_light_texel(param_8);\n    float _2815 = _2803.x * max(dot(_2793, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2820 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2843 = clamp(dot(n, _2793.xyz), -1.0f, 1.0f);\n    float _2862 = min(sqrt(1.0f - (_2843 * _2843)) / max(abs(dot(n, world - lpos)) / max(dot(_2793, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2865 = _2735.y;\n    float _2867;\n    if (_2865 > 0.0f)\n    {\n        _2867 = _2865;\n    }\n    else\n    {\n        _2867 = 1.5f * _2815;\n    }\n    float4 _2887 = float4(world + (n * (_2867 * sqrt(1.0f - (_2820 * _2820)))), 1.0f);\n    float _2891 = dot(_2793, _2887);\n    float _2894 = _2803.y;\n    if (_2891 < _2894)\n    {\n        return 1.0f;\n    }\n    float2 _2909 = float2(dot(fa_light_texel(param_4), _2887), dot(fa_light_texel(param_5), _2887)) / _2891.xx;\n    float _2911 = _2909.x;\n    bool _2914 = _2911 < _2798.x;\n    bool _2923;\n    if (!_2914)\n    {\n        _2923 = _2911 > _2798.z;\n    }\n    else\n    {\n        _2923 = _2914;\n    }\n    bool _2932;\n    if (!_2923)\n    {\n        _2932 = _2909.y < _2798.y;\n    }\n    else\n    {\n        _2932 = _2923;\n    }\n    bool _2941;\n    if (!_2932)\n    {\n        _2941 = _2909.y > _2798.w;\n    }\n    else\n    {\n        _2941 = _2932;\n    }\n    if (_2941)\n    {\n        return 1.0f;\n    }\n    float _2947 = _2735.x;\n    float _2949;\n    if (_2947 > 0.0f)\n    {\n        _2949 = _2947;\n    }\n    else\n    {\n        _2949 = 1.5f * _2815;\n    }\n    float2 param_9 = _2909;\n    float4 param_10 = _2798;\n    float param_11 = _2891 - (_2949 * (1.0f + (0.5f * _2862)));\n    float param_12 = _2815;\n    float param_13 = 1.0f;\n    float param_14 = _2803.z * 0.25f;\n    float param_15 = (_2815 * min(_2862, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2894, _2803.z);\n    int param_17 = int(_2730.z + 0.5f);\n    float param_18 = _2730.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4504 = _595_fa_ct_a.x < 0.5f;\n    bool _4511;\n    if (!_4504)\n    {\n        _4511 = _2262_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4511 = _4504;\n    }\n    if (_4511)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2262_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4524 = fa_light_texel(param);\n    float _4525 = _4524.y;\n    float len = _4525;\n    if (_4525 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4537 = length(world - _595_fa_camera_pos.xyz);\n    float _4547 = 1.0f - smoothstep(0.5f * _595_fa_ct_b.x, _595_fa_ct_b.x, _4537);\n    if (_4547 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4553 = len;\n    float _4556 = min(_4553, 0.89999997615814208984375f * dist);\n    len = _4556;\n    float _4561 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4537);\n    float _4566 = _4561 + (0.5f * _4556);\n    float3 _4572 = world + (gn * _4561);\n    float _4574 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4638;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4589 = (float(k) + _4574) * 0.083333335816860198974609375f;\n        float3 _4597 = _4572 + (l * (_4589 * len));\n        float4 _4603 = float4(_4597, 1.0f);\n        float _4609 = dot(_595_fa_ct_vpw, _4603);\n        if (_4609 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4629 = float2(dot(_595_fa_ct_vpx, _4603), dot(_595_fa_ct_vpy, _4603)) / _4609.xx;\n        float _4633 = _4629.x * 0.5f;\n        float _4634 = _4633 + 0.5f;\n        if (_595_fa_ct_a.y > 0.5f)\n        {\n            _4638 = (_4629.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4638 = 0.5f - (_4629.y * 0.5f);\n        }\n        bool _4654 = _4634 < 0.0f;\n        bool _4661;\n        if (!_4654)\n        {\n            _4661 = _4634 >= 1.0f;\n        }\n        else\n        {\n            _4661 = _4654;\n        }\n        bool _4668;\n        if (!_4661)\n        {\n            _4668 = _4638 < 0.0f;\n        }\n        else\n        {\n            _4668 = _4661;\n        }\n        bool _4675;\n        if (!_4668)\n        {\n            _4675 = _4638 >= 1.0f;\n        }\n        else\n        {\n            _4675 = _4668;\n        }\n        if (_4675)\n        {\n            break;\n        }\n        float4 _4694 = fa_screen_tex.Load(int3(int2(float2(_4634, _4638) * _595_fa_ct_a.zw), 0));\n        if (_4694.w < 0.5f)\n        {\n            continue;\n        }\n        float _4713 = (dot(_595_fa_ct_fwd.xyz, _4597) + _595_fa_ct_fwd.w) - _4694.x;\n        if ((_4713 > _4561) && (_4713 < _4566))\n        {\n            occ = max(occ, (1.0f - (_4589 * _4589)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4634, 0.5f - _4633), min(_4638, 1.0f - _4638))));\n        }\n    }\n    return 1.0f - (occ * _4547);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5179 = fa_baked_keep(param);\n    if (_5179 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7725 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7725;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5205 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7727 = _5205.color;\n    float _7728 = _5205.attenuation;\n    float _7729 = _5205.shadow;\n    bool _5208 = _5205.type == 0;\n    if (_5208 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5205.direction;\n        float _5219 = fa_shadow_factor(param_5, param_6);\n        _7729 = _5219;\n        _7727 *= _5219;\n    }\n    else\n    {\n        bool _5230 = _5205.type != 0;\n        bool _5236;\n        if (_5230)\n        {\n            _5236 = _7728 > 0.0f;\n        }\n        else\n        {\n            _5236 = _5230;\n        }\n        if (_5236)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5205.direction;\n            float _5255 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7729 = _5255;\n            _7727 *= _5255;\n        }\n    }\n    bool _5265 = _595_fa_ct_a.x > 0.5f;\n    bool _5271;\n    if (_5265)\n    {\n        _5271 = _7728 > 0.0f;\n    }\n    else\n    {\n        _5271 = _5265;\n    }\n    if (_5271)\n    {\n        float _5278;\n        if (_5208)\n        {\n            _5278 = 1000000000.0f;\n        }\n        else\n        {\n            _5278 = _5205._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5205.direction;\n        float param_18 = _5278;\n        float _5296 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7729 *= _5296;\n        _7727 *= _5296;\n    }\n    float _5309 = _7728;\n    float _5310 = _5309 * _5179;\n    _7728 = _5310;\n    float3 _5314 = _7727;\n    float3 _5315 = _5314 * _5179;\n    _7727 = _5315;\n    LightSample _7744 = { _5205.direction, _5315, _5310, _7729, _5205._distance, _5205.type };\n    return _7744;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5349 = v - (n * dot(v, n));\n    float3 t = _5349;\n    float _5353 = dot(_5349, _5349);\n    float l2 = _5353;\n    if (_5353 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5363;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5363 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5363 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5363;\n        l2 = dot(_5363, _5363);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5398 = dot(a, a);\n    float _5402 = dot(b, b);\n    if ((_5398 < 1.0000000195414813782625560981111e-24f) || (_5402 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5416 = a * rsqrt(_5398);\n    float3 _5421 = b * rsqrt(_5402);\n    float _5425 = dot(_5416, _5421);\n    float _5428 = abs(_5425);\n    float g = (((((((((((0.0416471660137176513671875f * _5428) - 0.1924748718738555908203125f) * _5428) + 0.4179156124591827392578125f) * _5428) - 0.616057217121124267578125f) * _5428) + 0.777722418308258056640625f) * _5428) - 0.999542415142059326171875f) * _5428) + 1.570791721343994140625f;\n    if (_5425 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5425 * _5425), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5416, _5421) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5485 = a.z > 0.0f;\n    bool _5489 = b.z > 0.0f;\n    if (_5485 && _5489)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5485 != _5489)\n        {\n            float3 _5524 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5524.z = 0.0f;\n            if (_5485)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5524;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5524;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5524;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5524;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5573 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5599 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5625 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5651 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5573;\n    float3 param_1 = _5599;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5599;\n    float3 param_7 = _5625;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5625;\n    float3 param_13 = _5651;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5651;\n    float3 param_19 = _5573;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5800 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5824 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5840 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5800;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5824;\n    float4 param_9 = m;\n    float3 param_10 = _5800;\n    float3 param_11 = _5824;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5840;\n    float4 param_14 = m;\n    float3 param_15 = _5800;\n    float3 param_16 = _5840;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5898 = fa_light_base(param);\n    int param_1 = _5898;\n    int param_2 = _5898 + 1;\n    int param_3 = _5898 + 2;\n    int param_4 = _5898 + 4;\n    float4 _5920 = fa_light_texel(param_4);\n    int param_5 = _5898 + 5;\n    float4 _5925 = fa_light_texel(param_5);\n    int param_6 = _5898 + 6;\n    float4 _5930 = fa_light_texel(param_6);\n    float _5931 = _5930.w;\n    float3 _5936 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5938 = _5931 < 1.5f;\n    bool _5945;\n    if (_5938)\n    {\n        _5945 = dot(normalize(fa_light_texel(param_3).xyz), _5936) >= 0.0f;\n    }\n    else\n    {\n        _5945 = _5938;\n    }\n    if (_5945)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5954 = (_5931 > 0.5f) && _5938;\n    float _5958 = _5954 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5961 = _5920.xyz;\n    float _5963 = _5920.w;\n    float3 _5969 = _5925.xyz;\n    float _5971 = _5925.w;\n    float3 up = _5969 * (_5971 * _5958);\n    float _5977;\n    if (_5954)\n    {\n        _5977 = (3.1415927410125732421875f * _5963) * _5963;\n    }\n    else\n    {\n        _5977 = (4.0f * _5963) * _5971;\n    }\n    if (_5931 > 1.5f)\n    {\n        float3 _6003 = cross(_5961, -_5936);\n        float3 perp = _6003;\n        float _6007 = dot(_6003, _6003);\n        float3 _6010;\n        if (_6007 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6010 = perp * rsqrt(_6007);\n        }\n        else\n        {\n            _6010 = _5969;\n        }\n        perp = _6010;\n        up = _6010 * _5971;\n    }\n    float _6031 = max(_5977, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6041 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6041;\n    float3 param_10 = n;\n    float3 param_11 = _5936;\n    float3 _6049 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6041;\n    float3 param_13 = n;\n    float3 param_14 = _5961 * (_5963 * _5958);\n    float3 _6057 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6041;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6065 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5931;\n    float3 param_20 = _6049;\n    float3 param_21 = _6057;\n    float3 param_22 = _6065;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6084 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6084;\n    float2 param_26 = _6084 + float2(64.0f, 0.0f);\n    float4 _6094 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5931;\n    float3 param_29 = _6049;\n    float3 param_30 = _6057;\n    float3 param_31 = _6065;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6094.x) + ((f90.xxx - f0) * _6094.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5936, _5936)) + _6031) / _6031) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4241 = 1.0f / alpha;\n    return ((2.0f + _4241) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4241)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4276 = max(dot(L.nc, l), 0.0f);\n    float _4282 = max(dot(L.nc, h), 0.0f);\n    float _4291 = ((_4282 * _4282) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4291) * _4291)) * (0.5f / max(lerp((2.0f * _4276) * L.coat_ndv, _4276 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4276)) * _4276;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6162;\n    if (L.sheen_on)\n    {\n        _6162 = L.sheen_scale;\n    }\n    else\n    {\n        _6162 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6162);\n    float3 _6175 = normalize(l + v);\n    int param_10 = li;\n    float3 _6186 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6195 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6175), 0.0f);\n        float param_13 = _6195;\n        float param_14 = ndv;\n        result += ((L.sheen * _6186) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6195)) * _6195) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6175;\n        float param_18 = max(dot(v, _6175), 0.0f);\n        result += (_6186 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4144 = tdh / at;\n    float _4148 = bdh / ab;\n    float _4160 = ((_4144 * _4144) + (_4148 * _4148)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4160) * _4160);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4340 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4419 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4419) * _4419);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4340);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4340));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3550 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3553 = _3550.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3553 * _3553, exp2((-9.27999973297119140625f) * ndv)) * _3553) + _3550.y)) + _3550.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_595_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _595_fa_env_horizon.w).xyz;\n    }\n    float _3404 = rough * rough;\n    float _3434 = 0.60000002384185791015625f * _3404;\n    return lerp(lerp(_595_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_595_fa_env_horizon.xyz, _595_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3404)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3434, 0.0500000007450580596923828125f + _3434, d.y).xxx), ((_595_fa_env_sky.xyz + _595_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3404 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4027;\n        if (L.aniso >= 0.0f)\n        {\n            _4027 = L.b;\n        }\n        else\n        {\n            _4027 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4027, v), _4027), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4060 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4060.x) + (L.f90.xxx * _4060.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4115 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4115.x) + _4115.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3592 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3592.x) + _3592.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_595_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_595_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _4817 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _4821 = fa_xm_origin(param_1);\n    float2 _4827 = (uv * _4817) - 0.5f.xx;\n    float2 _4830 = frac(_4827);\n    float2 _4833 = floor(_4827);\n    float2 param_2 = _4817;\n    float2 param_3 = _4821;\n    float2 param_4 = _4833;\n    float2 param_5 = _4817;\n    float2 param_6 = _4821;\n    float2 param_7 = _4833 + float2(1.0f, 0.0f);\n    float2 param_8 = _4817;\n    float2 param_9 = _4821;\n    float2 param_10 = _4833 + float2(0.0f, 1.0f);\n    float2 param_11 = _4817;\n    float2 param_12 = _4821;\n    float2 param_13 = _4833 + 1.0f.xx;\n    float3 _4875 = _4830.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4875), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4875), _4830.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _4894 = max(_595_fa_tr_b.w - 1.0f, 0.0f);\n    float _4898 = clamp(lod, 0.0f, _4894);\n    int _4902 = int(floor(_4898));\n    int param = _4902;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _4912 = float(_4902);\n    float _4913 = _4898 - _4912;\n    bool _4915 = _4913 > 0.001000000047497451305389404296875f;\n    bool _4922;\n    if (_4915)\n    {\n        _4922 = _4912 < _4894;\n    }\n    else\n    {\n        _4922 = _4915;\n    }\n    if (_4922)\n    {\n        int param_2 = _4902 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _4913.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4948 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _4948.x) + (f90.xxx * _4948.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _4976 = max(s.thickness, 0.0f);\n    bool _4981 = _4976 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _4981)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _4976);\n    }\n    bool _5006 = _595_fa_tr_a.w > 1.5f;\n    bool _5013;\n    if (!_5006)\n    {\n        _5013 = _595_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5013 = _5006;\n    }\n    if (_5013)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_4981)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _4976);\n    }\n    float4 _5048 = float4(world, 1.0f);\n    float _5053 = dot(_595_fa_ct_vpw, _5048);\n    float2 uv = 0.5f.xx;\n    if (_5053 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5071 = float2(dot(_595_fa_ct_vpx, _5048), dot(_595_fa_ct_vpy, _5048)) / _5053.xx;\n        float _5079;\n        if (_595_fa_ct_a.y > 0.5f)\n        {\n            _5079 = (_5071.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5079 = 0.5f - (_5071.y * 0.5f);\n        }\n        uv = float2((_5071.x * 0.5f) + 0.5f, _5079);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_595_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2262_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3198 = int(_2262_fa_shadow_cfg.x + 0.5f);\n    float _3208 = dot(world - _2262_fa_shadow_eye.xyz, _2262_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3213 = _3198 > 0;\n    bool _3222;\n    if (_3213)\n    {\n        int param = _3198 - 1;\n        _3222 = _3208 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3222 = _3213;\n    }\n    if (_3222)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3228 = _3198 > 1;\n        bool _3235;\n        if (_3228)\n        {\n            _3235 = _3208 > _2262_fa_shadow_split.x;\n        }\n        else\n        {\n            _3235 = _3228;\n        }\n        if (_3235)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3241 = _3198 > 2;\n        bool _3248;\n        if (_3241)\n        {\n            _3248 = _3208 > _2262_fa_shadow_split.y;\n        }\n        else\n        {\n            _3248 = _3241;\n        }\n        if (_3248)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3254 = _3198 > 3;\n        bool _3261;\n        if (_3254)\n        {\n            _3261 = _3208 > _2262_fa_shadow_split.z;\n        }\n        else\n        {\n            _3261 = _3254;\n        }\n        if (_3261)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _7386 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7386 = -_7386;\n    }\n    float3 _6681 = normalize(_595_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _7399 = { fa_world_pos, _7386, fa_world_tangent, fa_uv, fa_vertex_color, _6681, gl_FrontFacing };\n    SurfaceInput param_1 = _7399;\n    Surface _6689 = fa_standard_surface(param_1);\n    float3 _7417 = _6689.albedo;\n    float _7418 = _6689.alpha;\n    float3 _7419 = _6689.normal;\n    float _7420 = _6689.metallic;\n    float _7421 = _6689.roughness;\n    float _7422 = _6689.occlusion;\n    float3 _7423 = _6689.emission;\n    float _7424 = _6689.clearcoat;\n    float _7425 = _6689.clearcoat_roughness;\n    float3 _7426 = _6689.sheen_color;\n    float _7427 = _6689.sheen_roughness;\n    float _7428 = _6689.anisotropy;\n    float _7429 = _6689.anisotropy_rotation;\n    float _7430 = _6689.specular;\n    float _7431 = _6689.ior;\n    float3 _7432 = _6689.specular_color;\n    float _7433 = _6689.transmission;\n    float _7434 = _6689.thickness;\n    float3 _7435 = _6689.attenuation_color;\n    float _7436 = _6689.attenuation_distance;\n    SurfaceInput _7407 = { fa_world_pos, _7386, fa_world_tangent, fa_uv, fa_vertex_color, _6681, gl_FrontFacing };\n    SurfaceInput param_2 = _7407;\n    Surface param_3 = _6689;\n    surface(param_2, param_3);\n    _7417 = param_3.albedo;\n    _7418 = param_3.alpha;\n    _7419 = param_3.normal;\n    _7420 = param_3.metallic;\n    _7421 = param_3.roughness;\n    _7422 = param_3.occlusion;\n    _7423 = param_3.emission;\n    _7424 = param_3.clearcoat;\n    _7425 = param_3.clearcoat_roughness;\n    _7426 = param_3.sheen_color;\n    _7427 = param_3.sheen_roughness;\n    _7428 = param_3.anisotropy;\n    _7429 = param_3.anisotropy_rotation;\n    _7430 = param_3.specular;\n    _7431 = param_3.ior;\n    _7432 = param_3.specular_color;\n    _7433 = param_3.transmission;\n    _7434 = param_3.thickness;\n    _7435 = param_3.attenuation_color;\n    _7436 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _7386;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7417 = param_6;\n    _7419 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_595_fa_emissive.w > 0.5f)\n    {\n        result = _7417;\n    }\n    else\n    {\n        float3 _6729 = normalize(_7419);\n        float _6736 = clamp(_7420, 0.0f, 1.0f);\n        float _6740 = clamp(_7421, 0.0500000007450580596923828125f, 1.0f);\n        float _6744 = _6740 * _6740;\n        float _6748 = _6744 * _6744;\n        float _6753 = max(dot(_6729, _6681), 9.9999997473787516355514526367188e-05f);\n        float _6759 = 1.0f - _6736;\n        float _6760 = clamp(_7433, 0.0f, 1.0f) * _6759;\n        float3 _6769 = (_7417 * _6759) * (1.0f - _6760);\n        float3 _6776 = lerp(0.039999999105930328369140625f.xxx, _7417, _6736.xxx);\n        float3 f0 = _6776;\n        SurfaceInput _7415 = { fa_world_pos, _7386, fa_world_tangent, fa_uv, fa_vertex_color, _6681, gl_FrontFacing };\n        SurfaceInput param_8 = _7415;\n        Surface _7518 = { _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432, _7433, _7434, _7435, _7436 };\n        Surface param_9 = _7518;\n        float3 param_10 = _6729;\n        float3 param_11 = _6681;\n        float param_12 = _6736;\n        float param_13 = _6740;\n        float3 param_14 = _6776;\n        FaLayers _6792 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6729;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6769) * _7422;\n        if (_6792.on)\n        {\n            lit *= _6792.base_scale;\n        }\n        int _6814 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6814; ln++)\n        {\n            int param_16 = ln;\n            int _6827 = fa_cl_light(param_16);\n            int param_17 = _6827;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _6827;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _7386;\n            LightSample _6843 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6851 = max(dot(_6729, _6843.direction), 0.0f);\n            float _6857 = _6843.attenuation * _6843.shadow;\n            float3 _6862 = normalize(_6843.direction + _6681);\n            float _6867 = max(dot(_6729, _6862), 0.0f);\n            float _6872 = max(dot(_6681, _6862), 0.0f);\n            bool _6879;\n            if (fa_light_is_area)\n            {\n                _6879 = !_6792.on;\n            }\n            else\n            {\n                _6879 = fa_light_is_area;\n            }\n            if (_6879)\n            {\n                int param_21 = _6827;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6729;\n                float3 param_24 = _6681;\n                float3 param_25 = _6769;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6740;\n                float param_29 = _6753;\n                float param_30 = _6857;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6792;\n                    int param_32 = _6827;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6729;\n                    float3 param_35 = _6681;\n                    float3 param_36 = _6843.direction;\n                    float3 param_37 = _6769;\n                    float3 param_38 = f0;\n                    float param_39 = _6740;\n                    float param_40 = _6753;\n                    float param_41 = _6857;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6792.on)\n                    {\n                        FaLayers param_42 = _6792;\n                        float3 param_43 = _6769;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6729;\n                        float3 param_46 = _6681;\n                        float3 param_47 = _6843.direction;\n                        float3 param_48 = _6862;\n                        float param_49 = _6851;\n                        float param_50 = _6753;\n                        float param_51 = _6867;\n                        float param_52 = _6872;\n                        float param_53 = _6744;\n                        float param_54 = _6748;\n                        int param_55 = _6827;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6857));\n                    }\n                    else\n                    {\n                        float _6985 = ((_6867 * _6867) * (_6748 - 1.0f)) + 1.0f;\n                        int param_56 = _6827;\n                        lit += (((_6769 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6872, 5.0f))) * (((_6748 / ((3.1415927410125732421875f * _6985) * _6985)) * (0.5f / max(lerp((2.0f * _6851) * _6753, _6851 + _6753, _6744), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6851))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6851 * _6857));\n                    }\n                }\n            }\n        }\n        if (_6792.on)\n        {\n            FaLayers param_57 = _6792;\n            float3 param_58 = _6729;\n            float3 param_59 = _6681;\n            float3 param_60 = f0;\n            float param_61 = _6740;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7422);\n        }\n        else\n        {\n            float3 param_62 = _6729;\n            float3 param_63 = _6681;\n            float3 param_64 = f0;\n            float param_65 = _6740;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7422);\n        }\n        if (_6760 > 0.0f)\n        {\n            float _7083;\n            if (_6792.on)\n            {\n                _7083 = _6792.f90;\n            }\n            else\n            {\n                _7083 = 1.0f;\n            }\n            float _7091;\n            if (_6792.on)\n            {\n                _7091 = _6792.base_scale;\n            }\n            else\n            {\n                _7091 = 1.0f;\n            }\n            Surface _7539 = { _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432, _7433, _7434, _7435, _7436 };\n            Surface param_66 = _7539;\n            float3 param_67 = _6729;\n            float3 param_68 = _6681;\n            float param_69 = _6740;\n            float3 param_70 = f0;\n            float param_71 = _7083;\n            float param_72 = _7091;\n            float param_73 = _6760;\n            float param_74 = fa_tr_blend;\n            float3 _7115 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7115;\n        }\n        result = lit;\n    }\n    float3 _7122 = result;\n    float3 _7123 = _7122 + _7423;\n    result = _7123;\n    float3 param_75 = _7123;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7132 = _595_fa_fog.w > 0.0f;\n    bool _7139;\n    if (!_7132)\n    {\n        _7139 = _595_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7139 = _7132;\n    }\n    if (_7139)\n    {\n        float3 _7148 = fa_world_pos - _595_fa_camera_pos.xyz;\n        float _7154 = dot(_7148, _595_fa_fog_c.xyz);\n        bool _7158 = _595_fa_fog_c.w > 0.5f;\n        float _7159;\n        if (_7158)\n        {\n            _7159 = _7154;\n        }\n        else\n        {\n            _7159 = length(_7148);\n        }\n        float _7171 = _7159 - _595_fa_fog_b.x;\n        if (_7171 > 0.0f)\n        {\n            float _7180 = _595_fa_fog.w * _7171;\n            float tau = _7180 * _7180;\n            if (_595_fa_fog_b.y > 0.0f)\n            {\n                float _7196;\n                if (_7158)\n                {\n                    _7196 = fa_world_pos.y - (_595_fa_fog_c.y * _7154);\n                }\n                else\n                {\n                    _7196 = _595_fa_camera_pos.y;\n                }\n                float _7217 = lerp(_7196, fa_world_pos.y, clamp(_595_fa_fog_b.x / _7159, 0.0f, 1.0f));\n                float _7221 = fa_world_pos.y - _7217;\n                float _7226 = _7217 - _595_fa_fog_b.z;\n                float _7231 = fa_world_pos.y - _595_fa_fog_b.z;\n                bool _7234 = _7226 <= 0.0f;\n                bool _7235 = !_7234;\n                bool _7241;\n                if (_7235)\n                {\n                    _7241 = _595_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7241 = _7234;\n                }\n                float _7242;\n                if (_7241)\n                {\n                    _7242 = _595_fa_fog_b.y;\n                }\n                else\n                {\n                    _7242 = _595_fa_fog_b.y * exp(-min(_595_fa_fog_b.w * _7226, 80.0f));\n                }\n                bool _7269;\n                if (_7235)\n                {\n                    _7269 = _595_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7269 = _7234;\n                }\n                float _7270;\n                if (_7269)\n                {\n                    _7270 = _595_fa_fog_b.y * _7226;\n                }\n                else\n                {\n                    _7270 = (_595_fa_fog_b.y * (1.0f - exp(-min(_595_fa_fog_b.w * _7226, 80.0f)))) / _595_fa_fog_b.w;\n                }\n                bool _7295 = _7231 <= 0.0f;\n                bool _7302;\n                if (!_7295)\n                {\n                    _7302 = _595_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7302 = _7295;\n                }\n                float _7303;\n                if (_7302)\n                {\n                    _7303 = _595_fa_fog_b.y * _7231;\n                }\n                else\n                {\n                    _7303 = (_595_fa_fog_b.y * (1.0f - exp(-min(_595_fa_fog_b.w * _7231, 80.0f)))) / _595_fa_fog_b.w;\n                }\n                float _7330;\n                if (abs(_7221) < 0.001000000047497451305389404296875f)\n                {\n                    _7330 = _7242;\n                }\n                else\n                {\n                    _7330 = (_7303 - _7270) / _7221;\n                }\n                tau += (_7171 * max(_7330, 0.0f));\n            }\n            result = lerp(result, _595_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _7366 = 1.0f - fa_tr_blend;\n        result /= _7366.xxx;\n        _7418 *= _7366;\n    }\n    fa_frag_color = float4(result, _7418);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_168",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_238",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_595",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2262",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _173_fa_view_proj : packoffset(c0);\n    row_major float4x4 _173_fa_light_vp : packoffset(c4);\n    float4 _173_fa_uv_scale : packoffset(c8);\n    float4 _173_fa_time : packoffset(c9);\n    float4 _173_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _217_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _350_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_217_fa_joint_rows[_208] * weights[i]);\n        r1 += (_217_fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217_fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _399 = { mul(float4(position, 1.0f), model).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173_fa_uv_scale.xy, color, position };\n    return _399;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _173_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _350_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _3692[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _595_fa_camera_pos : packoffset(c0);\n    float4 _595_fa_ambient : packoffset(c1);\n    float4 _595_fa_base_color : packoffset(c2);\n    float4 _595_fa_emissive : packoffset(c3);\n    float4 _595_fa_model_emissive : packoffset(c4);\n    float4 _595_fa_pbr : packoffset(c5);\n    float4 _595_fa_maps : packoffset(c6);\n    float4 _595_fa_fog : packoffset(c7);\n    float4 _595_fa_fog_b : packoffset(c8);\n    float4 _595_fa_fog_c : packoffset(c9);\n    float4 _595_fa_counts : packoffset(c10);\n    float4 _595_fa_env_sky : packoffset(c11);\n    float4 _595_fa_env_horizon : packoffset(c12);\n    float4 _595_fa_time : packoffset(c13);\n    float4 _595_fa_cl_vpx : packoffset(c14);\n    float4 _595_fa_cl_vpy : packoffset(c15);\n    float4 _595_fa_cl_vpw : packoffset(c16);\n    float4 _595_fa_cl_fwd : packoffset(c17);\n    float4 _595_fa_cl_grid : packoffset(c18);\n    float4 _595_fa_cl_info : packoffset(c19);\n    float4 _595_fa_layers_a : packoffset(c20);\n    float4 _595_fa_layers_b : packoffset(c21);\n    float4 _595_fa_layers_c : packoffset(c22);\n    float4 _595_fa_layers_d : packoffset(c23);\n    float4 _595_fa_ct_a : packoffset(c24);\n    float4 _595_fa_ct_b : packoffset(c25);\n    float4 _595_fa_ct_vpx : packoffset(c26);\n    float4 _595_fa_ct_vpy : packoffset(c27);\n    float4 _595_fa_ct_vpw : packoffset(c28);\n    float4 _595_fa_ct_fwd : packoffset(c29);\n    float4 _595_fa_tr_a : packoffset(c30);\n    float4 _595_fa_tr_b : packoffset(c31);\n    float4 _595_fa_probe_sh[9] : packoffset(c32);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2262_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2262_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2262_fa_shadow_info[4] : packoffset(c20);\n    float4 _2262_fa_shadow_split : packoffset(c24);\n    float4 _2262_fa_shadow_cfg : packoffset(c25);\n    float4 _2262_fa_shadow_bias : packoffset(c26);\n    float4 _2262_fa_shadow_eye : packoffset(c27);\n    float4 _2262_fa_shadow_fwd : packoffset(c28);\n    float4 _2262_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1533 = _595_fa_cl_info.x < 0.0f;\n    bool _1540;\n    if (!_1533)\n    {\n        _1540 = _595_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1540 = _1533;\n    }\n    bool _1548;\n    if (!_1540)\n    {\n        _1548 = _595_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1548 = _1540;\n    }\n    bool _1555;\n    if (!_1548)\n    {\n        _1555 = _595_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1555 = _1548;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = _595_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    if (_1562)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1572 = float4(world_pos, 1.0f);\n    float _1578 = dot(_595_fa_cl_vpw, _1572);\n    if (!(_1578 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1600 = float2(dot(_595_fa_cl_vpx, _1572), dot(_595_fa_cl_vpy, _1572)) / _1578.xx;\n    int _1604 = int(_595_fa_cl_grid.x);\n    int _1608 = int(_595_fa_cl_grid.y);\n    int param = (int(_595_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_595_fa_cl_fwd.xyz, world_pos) + _595_fa_cl_fwd.w, _595_fa_cl_grid.w) / _595_fa_cl_grid.w) * _595_fa_cl_grid.z)), 0, int(_595_fa_cl_info.y) - 1) * _1608) + clamp(int(floor(((_1600.y * 0.5f) + 0.5f) * _595_fa_cl_grid.y)), 0, _1608 - 1)) * _1604)) + clamp(int(floor(((_1600.x * 0.5f) + 0.5f) * _595_fa_cl_grid.x)), 0, _1604 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1684 = fa_cluster_texel(param);\n    return int2(int(_1684.x), int(_1684.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_595_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5153 = fa_cluster_lookup(param);\n    fa_cl_slot = _5153.x;\n    fa_cl_local = _5153.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6301 = fa_linear_to_srgb(param);\n        c = _6301;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6309 = fa_srgb_to_linear(param_1);\n            c = _6309;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _477;\n    if (i.front_facing)\n    {\n        _477 = i.world_normal;\n    }\n    else\n    {\n        _477 = -i.world_normal;\n    }\n    float3 _501 = normalize(i.world_tangent.xyz - (_477 * dot(_477, i.world_tangent.xyz)));\n    float3 _528 = normalize(((_501 * m.x) + ((cross(_477, _501) * i.world_tangent.w) * m.y)) + (_477 * m.z));\n    float3 _531;\n    if (i.front_facing)\n    {\n        _531 = _528;\n    }\n    else\n    {\n        _531 = -_528;\n    }\n    return _531;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _595_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6340 = fa_tex_fix(param_2, param_3);\n    float4 _7938 = base_t;\n    _7938.x = _6340.x;\n    _7938.y = _6340.y;\n    _7938.z = _6340.z;\n    base_t = _7938;\n    float4 _6354 = (_7938 * _595_fa_base_color) * i.vertex_color;\n    float3 _7747 = i.world_normal;\n    if (_595_fa_maps.z > 0.5f)\n    {\n        float param_4 = _595_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _6386 = fa_tex_fix(param_6, param_7);\n        float3 _6389 = (_6386 * 2.0f) - 1.0f.xxx;\n        float2 _6394 = _6389.xy * _595_fa_maps.x;\n        float3 _7946 = _6389;\n        _7946.x = _6394.x;\n        _7946.y = _6394.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7946;\n        _7747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _595_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6422 = fa_tex_fix(param_12, param_13);\n    float4 _7949 = mrt;\n    _7949.x = _6422.x;\n    _7949.y = _6422.y;\n    _7949.z = _6422.z;\n    mrt = _7949;\n    float4 _6450 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _595_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6450.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6461 = fa_tex_fix(param_16, param_17);\n    float param_18 = _595_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6491 = fa_tex_fix(param_20, param_21);\n    float _7752 = _595_fa_layers_a.x;\n    float _7753 = _595_fa_layers_a.y;\n    float _7756 = _595_fa_layers_a.z;\n    float _7755 = _595_fa_layers_b.w;\n    float _7758 = _595_fa_layers_c.x;\n    if (_595_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_595_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7752 *= _6461.y;\n            _7753 *= _6461.z;\n            _7755 *= _6450.w;\n        }\n        if (_595_fa_layers_c.z > 1.5f)\n        {\n            _7756 *= mrt.x;\n            _7758 *= mrt.w;\n        }\n    }\n    Surface _7785 = { _6354.xyz, _6354.w, _7747, clamp(_595_fa_pbr.x * _6422.z, 0.0f, 1.0f), clamp(_595_fa_pbr.y * _6422.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_595_fa_maps.y * (_6461.x - 1.0f)), _595_fa_emissive.xyz + (_595_fa_model_emissive.xyz * _6491), _7752, _7753, _595_fa_layers_b.xyz, _7755, _7756, _595_fa_layers_a.w, _7758, _595_fa_layers_c.y, _595_fa_layers_d.xyz, _595_fa_tr_a.x, _595_fa_tr_a.y, _595_fa_tr_b.xyz, _595_fa_tr_a.z };\n    return _7785;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1764 = rect.zw - rect.xy;\n    float2 _1768 = _1764 * atlas;\n    float2 _1772 = ddx * _1768;\n    float2 _1776 = ddy * _1768;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1764), clamp(0.5f * log2(max(max(dot(_1772, _1772), dot(_1776, _1776)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1809 = _595_fa_counts.y < 0.5f;\n    bool _1816;\n    if (!_1809)\n    {\n        _1816 = _595_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1816 = _1809;\n    }\n    if (_1816)\n    {\n        return;\n    }\n    float3 _1822 = ddx(world_pos);\n    float3 _1825 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1829 = fa_cluster_texel(param);\n    int _1833 = int(_1829.w);\n    if (_1833 < 1)\n    {\n        return;\n    }\n    int _1843 = int(_595_fa_counts.y + 0.5f);\n    int param_1 = _1843;\n    float4 _1847 = fa_light_texel(param_1);\n    float2 _1850 = _1847.yz;\n    int _1854 = int(_1847.w);\n    int param_2 = _1843 + 1;\n    float4 _1859 = fa_light_texel(param_2);\n    float _1860 = _1859.x;\n    int _1866 = int(_595_fa_counts.w + 0.5f) - 1;\n    int _1870 = int(_1829.z);\n    float3 _2135;\n    for (int k = 0; k < _1833; k++)\n    {\n        int _1883 = _1870 + k;\n        int param_3 = _1854 + (_1883 >> 2);\n        int _1900 = (_1843 + 2) + (int(fa_light_texel(param_3)[_1883 & 3]) * 7);\n        int param_4 = _1900 + 6;\n        float4 _1905 = fa_light_texel(param_4);\n        if (((int(_1905.w + 0.5f) >> _1866) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1900;\n        float4 _1920 = fa_light_texel(param_5);\n        int param_6 = _1900 + 1;\n        float4 _1925 = fa_light_texel(param_6);\n        int param_7 = _1900 + 2;\n        float4 _1930 = fa_light_texel(param_7);\n        float3 _1933 = _1920.xyz;\n        float _1938 = dot(_1933, world_pos) + _1920.w;\n        float3 _1940 = _1925.xyz;\n        float _1945 = dot(_1940, world_pos) + _1925.w;\n        float3 _1947 = _1930.xyz;\n        float _1952 = dot(_1947, world_pos) + _1930.w;\n        bool _1957 = abs(_1938) > 0.5f;\n        bool _1965;\n        if (!_1957)\n        {\n            _1965 = abs(_1945) > 0.5f;\n        }\n        else\n        {\n            _1965 = _1957;\n        }\n        bool _1973;\n        if (!_1965)\n        {\n            _1973 = abs(_1952) > 0.5f;\n        }\n        else\n        {\n            _1973 = _1965;\n        }\n        if (_1973)\n        {\n            continue;\n        }\n        float _1988 = clamp(dot(geo_normal, normalize(_1947)) * _1905.z, 0.0f, 1.0f);\n        if (_1988 <= 0.0f)\n        {\n            continue;\n        }\n        float _2008 = (clamp((0.5f - abs(_1952)) * 10.0f, 0.0f, 1.0f) * _1988) * _1905.x;\n        float2 _2016 = float2(_1938 + 0.5f, 0.5f - _1945);\n        float2 _2026 = float2(dot(_1933, _1822), dot(_1940, _1822));\n        float2 _2036 = float2(dot(_1933, _1825), dot(_1940, _1825));\n        int param_8 = _1900 + 5;\n        float4 _2041 = fa_light_texel(param_8);\n        int param_9 = _1900 + 3;\n        float4 _2046 = fa_light_texel(param_9);\n        int param_10 = _1900 + 4;\n        float4 _2051 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2041.xyz;\n        bool _2061 = _2046.z > _2046.x;\n        if (_2061)\n        {\n            float4 param_11 = _2046;\n            float2 param_12 = _2016;\n            float2 param_13 = _1850;\n            float2 param_14 = _2026;\n            float2 param_15 = _2036;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1860 > 0.5f) && (_1860 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2087 = fa_dc_to_linear(param_16);\n                float4 _7835 = tx;\n                _7835.x = _2087.x;\n                _7835.y = _2087.y;\n                _7835.z = _2087.z;\n                tx = _7835;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2008 * tex_a) * _2041.w, 0.0f, 1.0f).xxx);\n        if (_2051.z > _2051.x)\n        {\n            float4 param_17 = _2051;\n            float2 param_18 = _2016;\n            float2 param_19 = _1850;\n            float2 param_20 = _2026;\n            float2 param_21 = _2036;\n            float4 _2131 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1860 > 1.5f)\n            {\n                float3 param_22 = _2131.xyz;\n                float3 _2141 = fa_dc_to_srgb(param_22);\n                _2135 = _2141;\n            }\n            else\n            {\n                _2135 = _2131.xyz;\n            }\n            float3 _2150 = (_2135 * 2.0f) - 1.0f.xxx;\n            float2 _2155 = _2150.xy * _1905.y;\n            float3 _2177 = (normalize(_1933) * _2155.x) + (normalize(_1940) * _2155.y);\n            float3 _2180 = normalize(normal);\n            normal = normalize(lerp(_2180, normalize((_2180 * max(_2150.z, 0.0500000007450580596923828125f)) + (_2177 - (_2180 * dot(_2180, _2177)))), clamp(_2008 * (_2061 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3618 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3625 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3628 = int(_3618);\n    int _3631 = int(_3625);\n    float _3641 = _3625 - float(_3631);\n    int _3696 = (_3628 * 9) + _3631;\n    int _3716 = ((_3628 + 1) * 9) + _3631;\n    return lerp(lerp(_3692[_3696], _3692[_3696 + 1], _3641), lerp(_3692[_3716], _3692[_3716 + 1], _3641), _3618 - float(_3628));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7670 = false;\n    float _7671 = 1.0f;\n    float _7672 = 1.0f;\n    float _7673 = 1.0f;\n    float _7674 = 0.0f;\n    float _7675 = 0.0f;\n    float _7676 = 0.0f;\n    float _7677 = 0.0f;\n    float _7679 = 1.0f;\n    bool _7680 = false;\n    float3 _7681 = 0.0f.xxx;\n    float _7682 = 1.0f;\n    float _7683 = 1.0f;\n    float _7684 = 1.0f;\n    float _7685 = 0.0f;\n    float _7686 = 0.0f;\n    float3 _7687 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7688 = float3(0.0f, 0.0f, 1.0f);\n    float _7689 = 1.0f;\n    float _7690 = 1.0f;\n    float _3767 = clamp(s.specular, 0.0f, 1.0f);\n    float _3771 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3776 = (_3767 != 1.0f) || (_3771 != 1.5f);\n    bool _3785;\n    if (!_3776)\n    {\n        _3785 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3785 = _3776;\n    }\n    if (_3785)\n    {\n        float _3793 = (_3771 - 1.0f) / (_3771 + 1.0f);\n        f0 = lerp(min((_3793 * _3793).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3767, s.albedo, metallic.xxx);\n        _7671 = lerp(_3767, 1.0f, metallic);\n        _7670 = true;\n    }\n    float _3820 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3820 > 0.0f)\n    {\n        float _3828 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7674 = _3820;\n        _7675 = _3828;\n        float _3835 = _3828 * _3828;\n        _7676 = _3835;\n        _7677 = _3835 * _3835;\n        float _3847 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7679 = _3847;\n        _7672 = 1.0f - (_3820 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3847, 0.0f, 1.0f), 5.0f))));\n        _7670 = true;\n    }\n    float3 _3866 = max(s.sheen_color, 0.0f.xxx);\n    float _3875 = max(_3866.x, max(_3866.y, _3866.z));\n    if (_3875 > 0.0f)\n    {\n        float _3883 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7680 = true;\n        _7681 = _3866;\n        _7682 = _3883;\n        _7683 = _3883 * _3883;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3883;\n        float _3900 = fa_sheen_albedo(param, param_1);\n        _7685 = _3900;\n        _7684 = 1.0f - min(_3875 * _3900, 1.0f);\n        _7670 = true;\n    }\n    _7673 = _7672 * _7684;\n    float _3919 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3919 != 0.0f)\n    {\n        float3 _3934 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3934;\n        if (dot(_3934, _3934) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3946 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3946.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3946.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3946.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3950 = t;\n        float3 _3951 = normalize(_3950);\n        t = _3951;\n        float3 _3976 = normalize((_3951 * cos(s.anisotropy_rotation)) + ((cross(n, _3951) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7687 = _3976;\n        _7688 = cross(n, _3976);\n        float _3986 = roughness * roughness;\n        float _3992 = lerp(_3986, 1.0f, _3919 * _3919);\n        bool _3994 = _3919 > 0.0f;\n        _7689 = _3994 ? _3992 : _3986;\n        _7690 = _3994 ? _3986 : _3992;\n        _7686 = _3919;\n        _7670 = true;\n    }\n    FaLayers _7712 = { _7670, _7671, _7672, _7673, _7674, _7675, _7676, _7677, i.world_normal, _7679, _7680, _7681, _7682, _7683, _7684, _7685, _7686, _7687, _7688, _7689, _7690 };\n    return _7712;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_595_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3375 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3375;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_595_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _595_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_595_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _595_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_595_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_595_fa_cl_info.x) + int(_595_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_595_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5123;\n    if (fa_lm.z > 0.5f)\n    {\n        _5123 = 0.0f;\n    }\n    else\n    {\n        _5123 = 1.0f - clamp(_595_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5134 = _5123 < 1.0f;\n    bool _5140;\n    if (_5134)\n    {\n        int param = li;\n        _5140 = fa_light_baked(param);\n    }\n    else\n    {\n        _5140 = _5134;\n    }\n    return _5140 ? _5123 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _663_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _663_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _782 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _795 = (c - (ru * hx)) - p;\n        float3 _801 = ru * (2.0f * hx);\n        float _807 = max(dot(_801, _801), 9.9999999392252902907785028219223e-09f);\n        float _811 = dot(_795, _801);\n        float t = clamp((-_811) / _807, 0.0f, 1.0f);\n        if (_782)\n        {\n            float _826 = dot(r, _801);\n            float _832 = _807 - (_826 * _826);\n            if (abs(_832) > (9.9999997473787516355514526367188e-06f * _807))\n            {\n                t = clamp(((dot(r, _795) * _826) - _811) / _832, 0.0f, 1.0f);\n            }\n        }\n        return (p + _795) + (_801 * t);\n    }\n    float3 q = p;\n    float _864 = dot(r, axis);\n    bool _872;\n    if (_782)\n    {\n        _872 = abs(_864) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _872 = _782;\n    }\n    if (_872)\n    {\n        float _882 = dot(c - p, axis) / _864;\n        if (_882 > 0.0f)\n        {\n            q = p + (r * _882);\n        }\n    }\n    float3 _895 = q - c;\n    float2 xy = float2(dot(_895, ru), dot(_895, uu));\n    if (shape > 0.5f)\n    {\n        float _910 = length(xy);\n        if (_910 > hx)\n        {\n            xy *= (hx / _910);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _543 = abs(d);\n    float _545 = _543.x;\n    float _547 = _543.y;\n    bool _548 = _545 >= _547;\n    bool _556;\n    if (_548)\n    {\n        _556 = _545 >= _543.z;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    int _557;\n    if (_556)\n    {\n        _557 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _572;\n        if (_547 >= _543.z)\n        {\n            _572 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _572 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _557 = _572;\n    }\n    return _557;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _702 = dot(d, right);\n    float _706 = dot(d, up);\n    float _717;\n    if (((_702 * _702) + (_706 * _706)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _717 = atan2(_706, _702) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _717 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_717 - floor(_717)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _948 = fa_light_base(param);\n    bool _952 = _595_fa_ambient.w > 4.5f;\n    int param_1 = _948;\n    float4 _956 = fa_light_texel(param_1);\n    int param_2 = _948 + 1;\n    float4 _961 = fa_light_texel(param_2);\n    float _964 = _961.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _976 = _952 && (_964 > 2.5f);\n    fa_light_is_area = _976;\n    bool _978 = _964 < 0.5f;\n    float3 l;\n    if (_978)\n    {\n        l = normalize(_956.xyz);\n        if (_952)\n        {\n            int param_3 = _948 + 6;\n            float4 _992 = fa_light_texel(param_3);\n            if (_992.z > 0.5f)\n            {\n                int param_4 = _948 + 4;\n                float4 _1002 = fa_light_texel(param_4);\n                int param_5 = _948 + 5;\n                float4 _1007 = fa_light_texel(param_5);\n                float2 param_6 = _992.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1002.xyz) * _1002.w, (-dot(world_pos, _1007.xyz)) * _1007.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1037 = _956.xyz;\n        float3 _1039 = _1037 - world_pos;\n        float3 to_light = _1039;\n        float _1042 = length(_1039);\n        float reach = _1042;\n        bool front = true;\n        if (_976)\n        {\n            int param_8 = _948 + 7;\n            reach = max(_1042 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _948 + 4;\n            float4 _1066 = fa_light_texel(param_9);\n            int param_10 = _948 + 5;\n            float4 _1071 = fa_light_texel(param_10);\n            int param_11 = _948 + 6;\n            float4 _1076 = fa_light_texel(param_11);\n            float _1077 = _1076.w;\n            int param_12 = _948 + 2;\n            float3 _1084 = normalize(fa_light_texel(param_12).xyz);\n            bool _1086 = _1077 > 1.5f;\n            bool _1094;\n            if (!_1086)\n            {\n                _1094 = dot(_1084, to_light) < 0.0f;\n            }\n            else\n            {\n                _1094 = _1086;\n            }\n            front = _1094;\n            float3 r = 0.0f.xxx;\n            float3 _1103 = _595_fa_camera_pos.xyz - world_pos;\n            bool _1107 = dot(n, n) > 0.5f;\n            bool _1115;\n            if (_1107)\n            {\n                _1115 = dot(_1103, _1103) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1115 = _1107;\n            }\n            if (_1115)\n            {\n                r = reflect(-normalize(_1103), normalize(n));\n            }\n            float3 param_13 = _1037;\n            float3 param_14 = _1084;\n            float3 param_15 = _1066.xyz;\n            float3 param_16 = _1071.xyz;\n            float param_17 = _1066.w;\n            float param_18 = _1071.w;\n            float param_19 = _1077;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1151 = length(to_light);\n        dist = _1151;\n        l = to_light / max(_1151, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1165 = reach / max(_956.w, 0.001000000047497451305389404296875f);\n        float _1171 = clamp(1.0f - (_1165 * _1165), 0.0f, 1.0f);\n        float _1173;\n        if (front)\n        {\n            _1173 = _1171 * _1171;\n        }\n        else\n        {\n            _1173 = 0.0f;\n        }\n        atten = _1173;\n        bool _1184 = _964 < 2.5f;\n        if ((_964 > 1.5f) && _1184)\n        {\n            int param_22 = _948 + 2;\n            float4 _1192 = fa_light_texel(param_22);\n            float _1202 = _1192.w;\n            int param_23 = _948 + 3;\n            float4 _1207 = fa_light_texel(param_23);\n            float _1208 = _1207.x;\n            float cos_inner = _1208;\n            if (_1208 > 1.5f)\n            {\n                cos_inner = lerp(_1202, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1202, cos_inner, dot(-l, normalize(_1192.xyz)));\n        }\n        if (_952 && (_964 < 1.5f))\n        {\n            int param_24 = _948 + 6;\n            float4 _1232 = fa_light_texel(param_24);\n            if (_1232.z > 0.5f)\n            {\n                float3 _1240 = -to_light;\n                int param_25 = _948 + 4;\n                int param_26 = _948 + 5;\n                float3 _1254 = fa_light_texel(param_25).xyz;\n                float3 _1258 = fa_light_texel(param_26).xyz;\n                float3 _1267 = float3(dot(_1240, _1254), dot(_1240, _1258), dot(_1240, cross(_1254, _1258)));\n                float3 param_27 = _1267;\n                int _1271 = fa_cube_face(param_27);\n                int param_28 = _1271;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1298 = float2(dot(_1267, cross(param_29, param_30)), dot(_1267, param_30)) / max(dot(_1267, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1302 = _1271 / 3;\n                float2 param_31 = _1232.xy + (float2(float(_1271 - (_1302 * 3)), float(_1302)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1298.x), 0.5f - (0.5f * _1298.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _948 + 7;\n            float4 _1332 = fa_light_texel(param_33);\n            if (_1332.z > 0.5f)\n            {\n                int param_34 = _948 + 2;\n                int param_35 = _948 + 4;\n                int param_36 = _948 + 5;\n                float2 param_37 = _1332.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_952 && _1184)\n            {\n                int param_42 = _948 + 6;\n                float4 _1379 = fa_light_texel(param_42);\n                int param_43 = _948 + 7;\n                float4 _1384 = fa_light_texel(param_43);\n                bool _1387 = _1379.z > 0.5f;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _1384.z > 0.5f;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                if (_1394)\n                {\n                    int param_44 = _948 + 2;\n                    float4 _1401 = fa_light_texel(param_44);\n                    float3 _1405 = normalize(_1401.xyz);\n                    int param_45 = _948 + 4;\n                    float4 _1410 = fa_light_texel(param_45);\n                    int param_46 = _948 + 5;\n                    float4 _1415 = fa_light_texel(param_46);\n                    if (_1387)\n                    {\n                        float3 _1423 = -to_light;\n                        float _1430 = _1401.w;\n                        float _1446 = 0.5f / max(dot(_1423, _1405) * (sqrt(max(1.0f - (_1430 * _1430), 0.0f)) / max(_1430, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1379.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1423, _1410.xyz) * _1446), 0.5f - (dot(_1423, _1415.xyz) * _1446));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1384.z > 0.5f)\n                    {\n                        float2 param_49 = _1384.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1405;\n                        float3 param_52 = _1410.xyz;\n                        float3 param_53 = _1415.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7658 = _961.xyz * atten;\n    if (_952)\n    {\n        _7658 *= fa_light_tint;\n    }\n    int _1515;\n    if (_978)\n    {\n        _1515 = 0;\n    }\n    else\n    {\n        _1515 = ((_964 > 1.5f) && (_964 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7669 = { l, _7658, atten, 1.0f, dist, _1515 };\n    return _7669;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2252;\n    if (i == 0)\n    {\n        _2252 = _2262_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2268;\n        if (i == 1)\n        {\n            _2268 = _2262_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2276;\n            if (i == 2)\n            {\n                _2276 = _2262_fa_shadow_split.z;\n            }\n            else\n            {\n                _2276 = _2262_fa_shadow_split.w;\n            }\n            _2268 = _2276;\n        }\n        _2252 = _2268;\n    }\n    return _2252;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2309 = fa_shadow_depth(param, param_1);\n    float _2313;\n    if (conv.x < 0.5f)\n    {\n        _2313 = _2309;\n    }\n    else\n    {\n        _2313 = (conv.y * conv.z) / (conv.z - (_2309 * (conv.z - conv.y)));\n    }\n    return _2313;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2240 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2240), sin(_2240)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2359 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2368;\n        if (k < 0.0f)\n        {\n            _2368 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2368 = k;\n        }\n        float _2388 = clamp((_2368 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2359;\n            float2 _2407 = fa_shadow_vogel(param_3, param_4, param_5) * _2388;\n            float2 param_6 = uv + (_2407 * _2262_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2419 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2419 < (zr - (length(_2407) * plane)))\n            {\n                sum += _2419;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2445 = sum / cnt;\n        float _2455;\n        if (k < 0.0f)\n        {\n            _2455 = (-k) / max(_2445, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2455 = k;\n        }\n        radius = clamp(((max(zr - _2445, 0.0f) * unit) * _2455) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2477 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2477; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2477;\n        float param_11 = _2359;\n        float2 _2496 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2496 * _2262_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2496) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2477);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2538 = max(_2262_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2543 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2549 = sqrt(1.0f - (_2543 * _2543));\n    float _2556 = min(_2549 / max(_2543, 0.20000000298023223876953125f), 4.0f);\n    float _2561;\n    if (_2262_fa_shadow_bias.y > 0.0f)\n    {\n        _2561 = _2262_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2561 = 1.5f * _2262_fa_shadow_info[ci].x;\n    }\n    float4 _2586 = mul(float4(world + (n * (_2561 * _2549)), 1.0f), _2262_fa_shadow_mat[ci]);\n    float _2593 = _2586.x;\n    bool _2596 = _2593 < _2262_fa_shadow_rect[ci].x;\n    bool _2605;\n    if (!_2596)\n    {\n        _2605 = _2593 > _2262_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2605 = _2596;\n    }\n    bool _2614;\n    if (!_2605)\n    {\n        _2614 = _2586.y < _2262_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2614 = _2605;\n    }\n    bool _2623;\n    if (!_2614)\n    {\n        _2623 = _2586.y > _2262_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2623 = _2614;\n    }\n    bool _2630;\n    if (!_2623)\n    {\n        _2630 = _2586.z > 1.0f;\n    }\n    else\n    {\n        _2630 = _2623;\n    }\n    if (_2630)\n    {\n        return -1.0f;\n    }\n    float _2638;\n    if (_2262_fa_shadow_bias.x > 0.0f)\n    {\n        _2638 = _2262_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2638 = 1.5f * _2262_fa_shadow_info[ci].x;\n    }\n    float2 param = _2586.xy;\n    float4 param_1 = _2262_fa_shadow_rect[ci];\n    float param_2 = _2586.z - ((_2638 * (1.0f + (0.5f * _2556))) / _2538);\n    float param_3 = _2262_fa_shadow_info[ci].x;\n    float param_4 = _2538;\n    float param_5 = _2538 * 0.25f;\n    float param_6 = ((_2262_fa_shadow_info[ci].x * min(_2556, 3.0f)) * 0.5f) / _2538;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2262_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2262_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_595_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3016 = int(_2262_fa_shadow_cfg.x + 0.5f);\n    if (_3016 < 1)\n    {\n        return 1.0f;\n    }\n    float _3031 = dot(world - _2262_fa_shadow_eye.xyz, _2262_fa_shadow_fwd.xyz);\n    int param = _3016 - 1;\n    if (_3031 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3043 = _3016 > 1;\n    bool _3050;\n    if (_3043)\n    {\n        _3050 = _3031 > _2262_fa_shadow_split.x;\n    }\n    else\n    {\n        _3050 = _3043;\n    }\n    if (_3050)\n    {\n        ci = 1;\n    }\n    bool _3054 = _3016 > 2;\n    bool _3061;\n    if (_3054)\n    {\n        _3061 = _3031 > _2262_fa_shadow_split.y;\n    }\n    else\n    {\n        _3061 = _3054;\n    }\n    if (_3061)\n    {\n        ci = 2;\n    }\n    bool _3065 = _3016 > 3;\n    bool _3072;\n    if (_3065)\n    {\n        _3072 = _3031 > _2262_fa_shadow_split.z;\n    }\n    else\n    {\n        _3072 = _3065;\n    }\n    if (_3072)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3016)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3098 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3098;\n        if (_3098 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2262_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3123;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3123 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3123 = _2262_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3142 = _2262_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3123, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3153 = clamp((_3031 - (fa_shadow_split_at(param_7) - _3142)) / _3142, 0.0f, 1.0f);\n        if (_3153 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3016)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3174 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3174;\n                if (_3174 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3153);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2696 = _595_fa_pbr.z < 0.5f;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = _2262_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2262_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2716 = fa_light_texel(param);\n    float _2717 = _2716.x;\n    if (_2717 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2726 = int(_2717 + 0.5f);\n    int param_1 = _2726;\n    float4 _2730 = fa_light_texel(param_1);\n    int param_2 = _2726 + 1;\n    float4 _2735 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2738 = _2730.y;\n    if (_2738 > 0.0f)\n    {\n        float _2755 = 1.0f - smoothstep(0.75f * _2738, _2738, length(world - _2262_fa_shadow_eye.xyz));\n        fade = _2755;\n        if (_2755 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2730.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2779 = (_2726 + 2) + (face * 6);\n    int param_4 = _2779;\n    int param_5 = _2779 + 1;\n    int param_6 = _2779 + 3;\n    float4 _2793 = fa_light_texel(param_6);\n    int param_7 = _2779 + 4;\n    float4 _2798 = fa_light_texel(param_7);\n    int param_8 = _2779 + 5;\n    float4 _2803 = fa_light_texel(param_8);\n    float _2815 = _2803.x * max(dot(_2793, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2820 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2843 = clamp(dot(n, _2793.xyz), -1.0f, 1.0f);\n    float _2862 = min(sqrt(1.0f - (_2843 * _2843)) / max(abs(dot(n, world - lpos)) / max(dot(_2793, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2865 = _2735.y;\n    float _2867;\n    if (_2865 > 0.0f)\n    {\n        _2867 = _2865;\n    }\n    else\n    {\n        _2867 = 1.5f * _2815;\n    }\n    float4 _2887 = float4(world + (n * (_2867 * sqrt(1.0f - (_2820 * _2820)))), 1.0f);\n    float _2891 = dot(_2793, _2887);\n    float _2894 = _2803.y;\n    if (_2891 < _2894)\n    {\n        return 1.0f;\n    }\n    float2 _2909 = float2(dot(fa_light_texel(param_4), _2887), dot(fa_light_texel(param_5), _2887)) / _2891.xx;\n    float _2911 = _2909.x;\n    bool _2914 = _2911 < _2798.x;\n    bool _2923;\n    if (!_2914)\n    {\n        _2923 = _2911 > _2798.z;\n    }\n    else\n    {\n        _2923 = _2914;\n    }\n    bool _2932;\n    if (!_2923)\n    {\n        _2932 = _2909.y < _2798.y;\n    }\n    else\n    {\n        _2932 = _2923;\n    }\n    bool _2941;\n    if (!_2932)\n    {\n        _2941 = _2909.y > _2798.w;\n    }\n    else\n    {\n        _2941 = _2932;\n    }\n    if (_2941)\n    {\n        return 1.0f;\n    }\n    float _2947 = _2735.x;\n    float _2949;\n    if (_2947 > 0.0f)\n    {\n        _2949 = _2947;\n    }\n    else\n    {\n        _2949 = 1.5f * _2815;\n    }\n    float2 param_9 = _2909;\n    float4 param_10 = _2798;\n    float param_11 = _2891 - (_2949 * (1.0f + (0.5f * _2862)));\n    float param_12 = _2815;\n    float param_13 = 1.0f;\n    float param_14 = _2803.z * 0.25f;\n    float param_15 = (_2815 * min(_2862, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2894, _2803.z);\n    int param_17 = int(_2730.z + 0.5f);\n    float param_18 = _2730.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4504 = _595_fa_ct_a.x < 0.5f;\n    bool _4511;\n    if (!_4504)\n    {\n        _4511 = _2262_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4511 = _4504;\n    }\n    if (_4511)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2262_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4524 = fa_light_texel(param);\n    float _4525 = _4524.y;\n    float len = _4525;\n    if (_4525 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4537 = length(world - _595_fa_camera_pos.xyz);\n    float _4547 = 1.0f - smoothstep(0.5f * _595_fa_ct_b.x, _595_fa_ct_b.x, _4537);\n    if (_4547 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4553 = len;\n    float _4556 = min(_4553, 0.89999997615814208984375f * dist);\n    len = _4556;\n    float _4561 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4537);\n    float _4566 = _4561 + (0.5f * _4556);\n    float3 _4572 = world + (gn * _4561);\n    float _4574 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4638;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4589 = (float(k) + _4574) * 0.083333335816860198974609375f;\n        float3 _4597 = _4572 + (l * (_4589 * len));\n        float4 _4603 = float4(_4597, 1.0f);\n        float _4609 = dot(_595_fa_ct_vpw, _4603);\n        if (_4609 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4629 = float2(dot(_595_fa_ct_vpx, _4603), dot(_595_fa_ct_vpy, _4603)) / _4609.xx;\n        float _4633 = _4629.x * 0.5f;\n        float _4634 = _4633 + 0.5f;\n        if (_595_fa_ct_a.y > 0.5f)\n        {\n            _4638 = (_4629.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4638 = 0.5f - (_4629.y * 0.5f);\n        }\n        bool _4654 = _4634 < 0.0f;\n        bool _4661;\n        if (!_4654)\n        {\n            _4661 = _4634 >= 1.0f;\n        }\n        else\n        {\n            _4661 = _4654;\n        }\n        bool _4668;\n        if (!_4661)\n        {\n            _4668 = _4638 < 0.0f;\n        }\n        else\n        {\n            _4668 = _4661;\n        }\n        bool _4675;\n        if (!_4668)\n        {\n            _4675 = _4638 >= 1.0f;\n        }\n        else\n        {\n            _4675 = _4668;\n        }\n        if (_4675)\n        {\n            break;\n        }\n        float4 _4694 = fa_screen_tex.Load(int3(int2(float2(_4634, _4638) * _595_fa_ct_a.zw), 0));\n        if (_4694.w < 0.5f)\n        {\n            continue;\n        }\n        float _4713 = (dot(_595_fa_ct_fwd.xyz, _4597) + _595_fa_ct_fwd.w) - _4694.x;\n        if ((_4713 > _4561) && (_4713 < _4566))\n        {\n            occ = max(occ, (1.0f - (_4589 * _4589)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4634, 0.5f - _4633), min(_4638, 1.0f - _4638))));\n        }\n    }\n    return 1.0f - (occ * _4547);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5179 = fa_baked_keep(param);\n    if (_5179 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7725 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7725;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5205 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7727 = _5205.color;\n    float _7728 = _5205.attenuation;\n    float _7729 = _5205.shadow;\n    bool _5208 = _5205.type == 0;\n    if (_5208 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5205.direction;\n        float _5219 = fa_shadow_factor(param_5, param_6);\n        _7729 = _5219;\n        _7727 *= _5219;\n    }\n    else\n    {\n        bool _5230 = _5205.type != 0;\n        bool _5236;\n        if (_5230)\n        {\n            _5236 = _7728 > 0.0f;\n        }\n        else\n        {\n            _5236 = _5230;\n        }\n        if (_5236)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5205.direction;\n            float _5255 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7729 = _5255;\n            _7727 *= _5255;\n        }\n    }\n    bool _5265 = _595_fa_ct_a.x > 0.5f;\n    bool _5271;\n    if (_5265)\n    {\n        _5271 = _7728 > 0.0f;\n    }\n    else\n    {\n        _5271 = _5265;\n    }\n    if (_5271)\n    {\n        float _5278;\n        if (_5208)\n        {\n            _5278 = 1000000000.0f;\n        }\n        else\n        {\n            _5278 = _5205._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5205.direction;\n        float param_18 = _5278;\n        float _5296 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7729 *= _5296;\n        _7727 *= _5296;\n    }\n    float _5309 = _7728;\n    float _5310 = _5309 * _5179;\n    _7728 = _5310;\n    float3 _5314 = _7727;\n    float3 _5315 = _5314 * _5179;\n    _7727 = _5315;\n    LightSample _7744 = { _5205.direction, _5315, _5310, _7729, _5205._distance, _5205.type };\n    return _7744;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5349 = v - (n * dot(v, n));\n    float3 t = _5349;\n    float _5353 = dot(_5349, _5349);\n    float l2 = _5353;\n    if (_5353 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _5363;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _5363 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _5363 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _5363;\n        l2 = dot(_5363, _5363);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5398 = dot(a, a);\n    float _5402 = dot(b, b);\n    if ((_5398 < 1.0000000195414813782625560981111e-24f) || (_5402 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5416 = a * rsqrt(_5398);\n    float3 _5421 = b * rsqrt(_5402);\n    float _5425 = dot(_5416, _5421);\n    float _5428 = abs(_5425);\n    float g = (((((((((((0.0416471660137176513671875f * _5428) - 0.1924748718738555908203125f) * _5428) + 0.4179156124591827392578125f) * _5428) - 0.616057217121124267578125f) * _5428) + 0.777722418308258056640625f) * _5428) - 0.999542415142059326171875f) * _5428) + 1.570791721343994140625f;\n    if (_5425 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5425 * _5425), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5416, _5421) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5485 = a.z > 0.0f;\n    bool _5489 = b.z > 0.0f;\n    if (_5485 && _5489)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5485 != _5489)\n        {\n            float3 _5524 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5524.z = 0.0f;\n            if (_5485)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5524;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5524;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5524;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5524;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5573 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5599 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5625 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5651 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5573;\n    float3 param_1 = _5599;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5599;\n    float3 param_7 = _5625;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5625;\n    float3 param_13 = _5651;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5651;\n    float3 param_19 = _5573;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5800 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5824 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5840 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5800;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5824;\n    float4 param_9 = m;\n    float3 param_10 = _5800;\n    float3 param_11 = _5824;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5840;\n    float4 param_14 = m;\n    float3 param_15 = _5800;\n    float3 param_16 = _5840;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5898 = fa_light_base(param);\n    int param_1 = _5898;\n    int param_2 = _5898 + 1;\n    int param_3 = _5898 + 2;\n    int param_4 = _5898 + 4;\n    float4 _5920 = fa_light_texel(param_4);\n    int param_5 = _5898 + 5;\n    float4 _5925 = fa_light_texel(param_5);\n    int param_6 = _5898 + 6;\n    float4 _5930 = fa_light_texel(param_6);\n    float _5931 = _5930.w;\n    float3 _5936 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5938 = _5931 < 1.5f;\n    bool _5945;\n    if (_5938)\n    {\n        _5945 = dot(normalize(fa_light_texel(param_3).xyz), _5936) >= 0.0f;\n    }\n    else\n    {\n        _5945 = _5938;\n    }\n    if (_5945)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5954 = (_5931 > 0.5f) && _5938;\n    float _5958 = _5954 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5961 = _5920.xyz;\n    float _5963 = _5920.w;\n    float3 _5969 = _5925.xyz;\n    float _5971 = _5925.w;\n    float3 up = _5969 * (_5971 * _5958);\n    float _5977;\n    if (_5954)\n    {\n        _5977 = (3.1415927410125732421875f * _5963) * _5963;\n    }\n    else\n    {\n        _5977 = (4.0f * _5963) * _5971;\n    }\n    if (_5931 > 1.5f)\n    {\n        float3 _6003 = cross(_5961, -_5936);\n        float3 perp = _6003;\n        float _6007 = dot(_6003, _6003);\n        float3 _6010;\n        if (_6007 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6010 = perp * rsqrt(_6007);\n        }\n        else\n        {\n            _6010 = _5969;\n        }\n        perp = _6010;\n        up = _6010 * _5971;\n    }\n    float _6031 = max(_5977, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6041 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6041;\n    float3 param_10 = n;\n    float3 param_11 = _5936;\n    float3 _6049 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6041;\n    float3 param_13 = n;\n    float3 param_14 = _5961 * (_5963 * _5958);\n    float3 _6057 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6041;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6065 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5931;\n    float3 param_20 = _6049;\n    float3 param_21 = _6057;\n    float3 param_22 = _6065;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6084 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6084;\n    float2 param_26 = _6084 + float2(64.0f, 0.0f);\n    float4 _6094 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5931;\n    float3 param_29 = _6049;\n    float3 param_30 = _6057;\n    float3 param_31 = _6065;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6094.x) + ((f90.xxx - f0) * _6094.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5936, _5936)) + _6031) / _6031) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4241 = 1.0f / alpha;\n    return ((2.0f + _4241) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4241)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4276 = max(dot(L.nc, l), 0.0f);\n    float _4282 = max(dot(L.nc, h), 0.0f);\n    float _4291 = ((_4282 * _4282) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4291) * _4291)) * (0.5f / max(lerp((2.0f * _4276) * L.coat_ndv, _4276 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4276)) * _4276;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6162;\n    if (L.sheen_on)\n    {\n        _6162 = L.sheen_scale;\n    }\n    else\n    {\n        _6162 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6162);\n    float3 _6175 = normalize(l + v);\n    int param_10 = li;\n    float3 _6186 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6195 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6175), 0.0f);\n        float param_13 = _6195;\n        float param_14 = ndv;\n        result += ((L.sheen * _6186) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6195)) * _6195) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6175;\n        float param_18 = max(dot(v, _6175), 0.0f);\n        result += (_6186 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4144 = tdh / at;\n    float _4148 = bdh / ab;\n    float _4160 = ((_4144 * _4144) + (_4148 * _4148)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4160) * _4160);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4340 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4419 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4419) * _4419);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4340);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4340));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3550 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3553 = _3550.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3553 * _3553, exp2((-9.27999973297119140625f) * ndv)) * _3553) + _3550.y)) + _3550.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_595_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _595_fa_env_horizon.w).xyz;\n    }\n    float _3404 = rough * rough;\n    float _3434 = 0.60000002384185791015625f * _3404;\n    return lerp(lerp(_595_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_595_fa_env_horizon.xyz, _595_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3404)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3434, 0.0500000007450580596923828125f + _3434, d.y).xxx), ((_595_fa_env_sky.xyz + _595_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3404 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4027;\n        if (L.aniso >= 0.0f)\n        {\n            _4027 = L.b;\n        }\n        else\n        {\n            _4027 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4027, v), _4027), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4060 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4060.x) + (L.f90.xxx * _4060.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4115 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4115.x) + _4115.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3592 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3592.x) + _3592.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_595_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_595_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _4817 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _4821 = fa_xm_origin(param_1);\n    float2 _4827 = (uv * _4817) - 0.5f.xx;\n    float2 _4830 = frac(_4827);\n    float2 _4833 = floor(_4827);\n    float2 param_2 = _4817;\n    float2 param_3 = _4821;\n    float2 param_4 = _4833;\n    float2 param_5 = _4817;\n    float2 param_6 = _4821;\n    float2 param_7 = _4833 + float2(1.0f, 0.0f);\n    float2 param_8 = _4817;\n    float2 param_9 = _4821;\n    float2 param_10 = _4833 + float2(0.0f, 1.0f);\n    float2 param_11 = _4817;\n    float2 param_12 = _4821;\n    float2 param_13 = _4833 + 1.0f.xx;\n    float3 _4875 = _4830.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4875), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4875), _4830.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _4894 = max(_595_fa_tr_b.w - 1.0f, 0.0f);\n    float _4898 = clamp(lod, 0.0f, _4894);\n    int _4902 = int(floor(_4898));\n    int param = _4902;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _4912 = float(_4902);\n    float _4913 = _4898 - _4912;\n    bool _4915 = _4913 > 0.001000000047497451305389404296875f;\n    bool _4922;\n    if (_4915)\n    {\n        _4922 = _4912 < _4894;\n    }\n    else\n    {\n        _4922 = _4915;\n    }\n    if (_4922)\n    {\n        int param_2 = _4902 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _4913.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4948 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _4948.x) + (f90.xxx * _4948.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _4976 = max(s.thickness, 0.0f);\n    bool _4981 = _4976 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _4981)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _4976);\n    }\n    bool _5006 = _595_fa_tr_a.w > 1.5f;\n    bool _5013;\n    if (!_5006)\n    {\n        _5013 = _595_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5013 = _5006;\n    }\n    if (_5013)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_4981)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _4976);\n    }\n    float4 _5048 = float4(world, 1.0f);\n    float _5053 = dot(_595_fa_ct_vpw, _5048);\n    float2 uv = 0.5f.xx;\n    if (_5053 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5071 = float2(dot(_595_fa_ct_vpx, _5048), dot(_595_fa_ct_vpy, _5048)) / _5053.xx;\n        float _5079;\n        if (_595_fa_ct_a.y > 0.5f)\n        {\n            _5079 = (_5071.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5079 = 0.5f - (_5071.y * 0.5f);\n        }\n        uv = float2((_5071.x * 0.5f) + 0.5f, _5079);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_595_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2262_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3198 = int(_2262_fa_shadow_cfg.x + 0.5f);\n    float _3208 = dot(world - _2262_fa_shadow_eye.xyz, _2262_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3213 = _3198 > 0;\n    bool _3222;\n    if (_3213)\n    {\n        int param = _3198 - 1;\n        _3222 = _3208 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3222 = _3213;\n    }\n    if (_3222)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3228 = _3198 > 1;\n        bool _3235;\n        if (_3228)\n        {\n            _3235 = _3208 > _2262_fa_shadow_split.x;\n        }\n        else\n        {\n            _3235 = _3228;\n        }\n        if (_3235)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3241 = _3198 > 2;\n        bool _3248;\n        if (_3241)\n        {\n            _3248 = _3208 > _2262_fa_shadow_split.y;\n        }\n        else\n        {\n            _3248 = _3241;\n        }\n        if (_3248)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3254 = _3198 > 3;\n        bool _3261;\n        if (_3254)\n        {\n            _3261 = _3208 > _2262_fa_shadow_split.z;\n        }\n        else\n        {\n            _3261 = _3254;\n        }\n        if (_3261)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _7386 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7386 = -_7386;\n    }\n    float3 _6681 = normalize(_595_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _7399 = { fa_world_pos, _7386, fa_world_tangent, fa_uv, fa_vertex_color, _6681, gl_FrontFacing };\n    SurfaceInput param_1 = _7399;\n    Surface _6689 = fa_standard_surface(param_1);\n    float3 _7417 = _6689.albedo;\n    float _7418 = _6689.alpha;\n    float3 _7419 = _6689.normal;\n    float _7420 = _6689.metallic;\n    float _7421 = _6689.roughness;\n    float _7422 = _6689.occlusion;\n    float3 _7423 = _6689.emission;\n    float _7424 = _6689.clearcoat;\n    float _7425 = _6689.clearcoat_roughness;\n    float3 _7426 = _6689.sheen_color;\n    float _7427 = _6689.sheen_roughness;\n    float _7428 = _6689.anisotropy;\n    float _7429 = _6689.anisotropy_rotation;\n    float _7430 = _6689.specular;\n    float _7431 = _6689.ior;\n    float3 _7432 = _6689.specular_color;\n    float _7433 = _6689.transmission;\n    float _7434 = _6689.thickness;\n    float3 _7435 = _6689.attenuation_color;\n    float _7436 = _6689.attenuation_distance;\n    SurfaceInput _7407 = { fa_world_pos, _7386, fa_world_tangent, fa_uv, fa_vertex_color, _6681, gl_FrontFacing };\n    SurfaceInput param_2 = _7407;\n    Surface param_3 = _6689;\n    surface(param_2, param_3);\n    _7417 = param_3.albedo;\n    _7418 = param_3.alpha;\n    _7419 = param_3.normal;\n    _7420 = param_3.metallic;\n    _7421 = param_3.roughness;\n    _7422 = param_3.occlusion;\n    _7423 = param_3.emission;\n    _7424 = param_3.clearcoat;\n    _7425 = param_3.clearcoat_roughness;\n    _7426 = param_3.sheen_color;\n    _7427 = param_3.sheen_roughness;\n    _7428 = param_3.anisotropy;\n    _7429 = param_3.anisotropy_rotation;\n    _7430 = param_3.specular;\n    _7431 = param_3.ior;\n    _7432 = param_3.specular_color;\n    _7433 = param_3.transmission;\n    _7434 = param_3.thickness;\n    _7435 = param_3.attenuation_color;\n    _7436 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _7386;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7417 = param_6;\n    _7419 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_595_fa_emissive.w > 0.5f)\n    {\n        result = _7417;\n    }\n    else\n    {\n        float3 _6729 = normalize(_7419);\n        float _6736 = clamp(_7420, 0.0f, 1.0f);\n        float _6740 = clamp(_7421, 0.0500000007450580596923828125f, 1.0f);\n        float _6744 = _6740 * _6740;\n        float _6748 = _6744 * _6744;\n        float _6753 = max(dot(_6729, _6681), 9.9999997473787516355514526367188e-05f);\n        float _6759 = 1.0f - _6736;\n        float _6760 = clamp(_7433, 0.0f, 1.0f) * _6759;\n        float3 _6769 = (_7417 * _6759) * (1.0f - _6760);\n        float3 _6776 = lerp(0.039999999105930328369140625f.xxx, _7417, _6736.xxx);\n        float3 f0 = _6776;\n        SurfaceInput _7415 = { fa_world_pos, _7386, fa_world_tangent, fa_uv, fa_vertex_color, _6681, gl_FrontFacing };\n        SurfaceInput param_8 = _7415;\n        Surface _7518 = { _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432, _7433, _7434, _7435, _7436 };\n        Surface param_9 = _7518;\n        float3 param_10 = _6729;\n        float3 param_11 = _6681;\n        float param_12 = _6736;\n        float param_13 = _6740;\n        float3 param_14 = _6776;\n        FaLayers _6792 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6729;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6769) * _7422;\n        if (_6792.on)\n        {\n            lit *= _6792.base_scale;\n        }\n        int _6814 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6814; ln++)\n        {\n            int param_16 = ln;\n            int _6827 = fa_cl_light(param_16);\n            int param_17 = _6827;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _6827;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _7386;\n            LightSample _6843 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6851 = max(dot(_6729, _6843.direction), 0.0f);\n            float _6857 = _6843.attenuation * _6843.shadow;\n            float3 _6862 = normalize(_6843.direction + _6681);\n            float _6867 = max(dot(_6729, _6862), 0.0f);\n            float _6872 = max(dot(_6681, _6862), 0.0f);\n            bool _6879;\n            if (fa_light_is_area)\n            {\n                _6879 = !_6792.on;\n            }\n            else\n            {\n                _6879 = fa_light_is_area;\n            }\n            if (_6879)\n            {\n                int param_21 = _6827;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6729;\n                float3 param_24 = _6681;\n                float3 param_25 = _6769;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6740;\n                float param_29 = _6753;\n                float param_30 = _6857;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6792;\n                    int param_32 = _6827;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6729;\n                    float3 param_35 = _6681;\n                    float3 param_36 = _6843.direction;\n                    float3 param_37 = _6769;\n                    float3 param_38 = f0;\n                    float param_39 = _6740;\n                    float param_40 = _6753;\n                    float param_41 = _6857;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6792.on)\n                    {\n                        FaLayers param_42 = _6792;\n                        float3 param_43 = _6769;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6729;\n                        float3 param_46 = _6681;\n                        float3 param_47 = _6843.direction;\n                        float3 param_48 = _6862;\n                        float param_49 = _6851;\n                        float param_50 = _6753;\n                        float param_51 = _6867;\n                        float param_52 = _6872;\n                        float param_53 = _6744;\n                        float param_54 = _6748;\n                        int param_55 = _6827;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6857));\n                    }\n                    else\n                    {\n                        float _6985 = ((_6867 * _6867) * (_6748 - 1.0f)) + 1.0f;\n                        int param_56 = _6827;\n                        lit += (((_6769 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6872, 5.0f))) * (((_6748 / ((3.1415927410125732421875f * _6985) * _6985)) * (0.5f / max(lerp((2.0f * _6851) * _6753, _6851 + _6753, _6744), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6851))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6851 * _6857));\n                    }\n                }\n            }\n        }\n        if (_6792.on)\n        {\n            FaLayers param_57 = _6792;\n            float3 param_58 = _6729;\n            float3 param_59 = _6681;\n            float3 param_60 = f0;\n            float param_61 = _6740;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7422);\n        }\n        else\n        {\n            float3 param_62 = _6729;\n            float3 param_63 = _6681;\n            float3 param_64 = f0;\n            float param_65 = _6740;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7422);\n        }\n        if (_6760 > 0.0f)\n        {\n            float _7083;\n            if (_6792.on)\n            {\n                _7083 = _6792.f90;\n            }\n            else\n            {\n                _7083 = 1.0f;\n            }\n            float _7091;\n            if (_6792.on)\n            {\n                _7091 = _6792.base_scale;\n            }\n            else\n            {\n                _7091 = 1.0f;\n            }\n            Surface _7539 = { _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432, _7433, _7434, _7435, _7436 };\n            Surface param_66 = _7539;\n            float3 param_67 = _6729;\n            float3 param_68 = _6681;\n            float param_69 = _6740;\n            float3 param_70 = f0;\n            float param_71 = _7083;\n            float param_72 = _7091;\n            float param_73 = _6760;\n            float param_74 = fa_tr_blend;\n            float3 _7115 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7115;\n        }\n        result = lit;\n    }\n    float3 _7122 = result;\n    float3 _7123 = _7122 + _7423;\n    result = _7123;\n    float3 param_75 = _7123;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7132 = _595_fa_fog.w > 0.0f;\n    bool _7139;\n    if (!_7132)\n    {\n        _7139 = _595_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _7139 = _7132;\n    }\n    if (_7139)\n    {\n        float3 _7148 = fa_world_pos - _595_fa_camera_pos.xyz;\n        float _7154 = dot(_7148, _595_fa_fog_c.xyz);\n        bool _7158 = _595_fa_fog_c.w > 0.5f;\n        float _7159;\n        if (_7158)\n        {\n            _7159 = _7154;\n        }\n        else\n        {\n            _7159 = length(_7148);\n        }\n        float _7171 = _7159 - _595_fa_fog_b.x;\n        if (_7171 > 0.0f)\n        {\n            float _7180 = _595_fa_fog.w * _7171;\n            float tau = _7180 * _7180;\n            if (_595_fa_fog_b.y > 0.0f)\n            {\n                float _7196;\n                if (_7158)\n                {\n                    _7196 = fa_world_pos.y - (_595_fa_fog_c.y * _7154);\n                }\n                else\n                {\n                    _7196 = _595_fa_camera_pos.y;\n                }\n                float _7217 = lerp(_7196, fa_world_pos.y, clamp(_595_fa_fog_b.x / _7159, 0.0f, 1.0f));\n                float _7221 = fa_world_pos.y - _7217;\n                float _7226 = _7217 - _595_fa_fog_b.z;\n                float _7231 = fa_world_pos.y - _595_fa_fog_b.z;\n                bool _7234 = _7226 <= 0.0f;\n                bool _7235 = !_7234;\n                bool _7241;\n                if (_7235)\n                {\n                    _7241 = _595_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7241 = _7234;\n                }\n                float _7242;\n                if (_7241)\n                {\n                    _7242 = _595_fa_fog_b.y;\n                }\n                else\n                {\n                    _7242 = _595_fa_fog_b.y * exp(-min(_595_fa_fog_b.w * _7226, 80.0f));\n                }\n                bool _7269;\n                if (_7235)\n                {\n                    _7269 = _595_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7269 = _7234;\n                }\n                float _7270;\n                if (_7269)\n                {\n                    _7270 = _595_fa_fog_b.y * _7226;\n                }\n                else\n                {\n                    _7270 = (_595_fa_fog_b.y * (1.0f - exp(-min(_595_fa_fog_b.w * _7226, 80.0f)))) / _595_fa_fog_b.w;\n                }\n                bool _7295 = _7231 <= 0.0f;\n                bool _7302;\n                if (!_7295)\n                {\n                    _7302 = _595_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _7302 = _7295;\n                }\n                float _7303;\n                if (_7302)\n                {\n                    _7303 = _595_fa_fog_b.y * _7231;\n                }\n                else\n                {\n                    _7303 = (_595_fa_fog_b.y * (1.0f - exp(-min(_595_fa_fog_b.w * _7231, 80.0f)))) / _595_fa_fog_b.w;\n                }\n                float _7330;\n                if (abs(_7221) < 0.001000000047497451305389404296875f)\n                {\n                    _7330 = _7242;\n                }\n                else\n                {\n                    _7330 = (_7303 - _7270) / _7221;\n                }\n                tau += (_7171 * max(_7330, 0.0f));\n            }\n            result = lerp(result, _595_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _7366 = 1.0f - fa_tr_blend;\n        result /= _7366.xxx;\n        _7418 *= _7366;\n    }\n    fa_frag_color = float4(result, _7418);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_173",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_350",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_595",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2262",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _168_fa_view_proj : packoffset(c0);\n    row_major float4x4 _168_fa_light_vp : packoffset(c4);\n    float4 _168_fa_uv_scale : packoffset(c8);\n    float4 _168_fa_time : packoffset(c9);\n    float4 _168_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _272_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _311 = { mul(float4(position, 1.0f), model).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * _168_fa_uv_scale.xy, color, position };\n    return _311;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _210 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_210, _168_fa_light_vp).z;\n    fa_pre_r0 = float3(_168_fa_light_vp[0].x, _168_fa_light_vp[1].x, _168_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_168_fa_light_vp[0].y, _168_fa_light_vp[1].y, _168_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_168_fa_light_vp[0].z, _168_fa_light_vp[1].z, _168_fa_light_vp[2].z);\n    gl_Position = mul(_210, _168_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _272_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _233_fa_camera_pos : packoffset(c0);\n    float4 _233_fa_ambient : packoffset(c1);\n    float4 _233_fa_base_color : packoffset(c2);\n    float4 _233_fa_emissive : packoffset(c3);\n    float4 _233_fa_model_emissive : packoffset(c4);\n    float4 _233_fa_pbr : packoffset(c5);\n    float4 _233_fa_maps : packoffset(c6);\n    float4 _233_fa_fog : packoffset(c7);\n    float4 _233_fa_fog_b : packoffset(c8);\n    float4 _233_fa_fog_c : packoffset(c9);\n    float4 _233_fa_counts : packoffset(c10);\n    float4 _233_fa_env_sky : packoffset(c11);\n    float4 _233_fa_env_horizon : packoffset(c12);\n    float4 _233_fa_time : packoffset(c13);\n    float4 _233_fa_cl_vpx : packoffset(c14);\n    float4 _233_fa_cl_vpy : packoffset(c15);\n    float4 _233_fa_cl_vpw : packoffset(c16);\n    float4 _233_fa_cl_fwd : packoffset(c17);\n    float4 _233_fa_cl_grid : packoffset(c18);\n    float4 _233_fa_cl_info : packoffset(c19);\n    float4 _233_fa_layers_a : packoffset(c20);\n    float4 _233_fa_layers_b : packoffset(c21);\n    float4 _233_fa_layers_c : packoffset(c22);\n    float4 _233_fa_layers_d : packoffset(c23);\n    float4 _233_fa_ct_a : packoffset(c24);\n    float4 _233_fa_ct_b : packoffset(c25);\n    float4 _233_fa_ct_vpx : packoffset(c26);\n    float4 _233_fa_ct_vpy : packoffset(c27);\n    float4 _233_fa_ct_vpw : packoffset(c28);\n    float4 _233_fa_ct_fwd : packoffset(c29);\n    float4 _233_fa_tr_a : packoffset(c30);\n    float4 _233_fa_tr_b : packoffset(c31);\n    float4 _233_fa_probe_sh[9] : packoffset(c32);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _233_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _244 = fa_tex_fix(param_2, param_3);\n    float4 _795 = base_t;\n    _795.x = _244.x;\n    _795.y = _244.y;\n    _795.z = _244.z;\n    base_t = _795;\n    float4 _259 = (_795 * _233_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_233_fa_maps.z > 0.5f)\n    {\n        float param_4 = _233_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _292 = fa_tex_fix(param_6, param_7);\n        float3 _296 = (_292 * 2.0f) - 1.0f.xxx;\n        float2 _301 = _296.xy * _233_fa_maps.x;\n        float3 _803 = _296;\n        _803.x = _301.x;\n        _803.y = _301.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _803;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _233_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _330 = fa_tex_fix(param_12, param_13);\n    float4 _806 = mrt;\n    _806.x = _330.x;\n    _806.y = _330.y;\n    _806.z = _330.z;\n    mrt = _806;\n    float4 _360 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _233_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _360.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _233_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _402 = fa_tex_fix(param_20, param_21);\n    float _755 = _233_fa_layers_a.x;\n    float _756 = _233_fa_layers_a.y;\n    float _759 = _233_fa_layers_a.z;\n    float _758 = _233_fa_layers_b.w;\n    float _761 = _233_fa_layers_c.x;\n    if (_233_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_233_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _372.y;\n            _756 *= _372.z;\n            _758 *= _360.w;\n        }\n        if (_233_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _788 = { _259.xyz, _259.w, _750, clamp(_233_fa_pbr.x * _330.z, 0.0f, 1.0f), clamp(_233_fa_pbr.y * _330.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_233_fa_maps.y * (_372.x - 1.0f)), _233_fa_emissive.xyz + (_233_fa_model_emissive.xyz * _402), _755, _756, _233_fa_layers_b.xyz, _758, _759, _233_fa_layers_a.w, _761, _233_fa_layers_c.y, _233_fa_layers_d.xyz, _233_fa_tr_a.x, _233_fa_tr_a.y, _233_fa_tr_b.xyz, _233_fa_tr_a.z };\n    return _788;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    float3 _555 = normalize(_233_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _658 = { fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param = _658;\n    SurfaceInput _666 = { fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param_1 = _666;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _570 = normalize(param_2.normal);\n    float3 _585 = normalize(float3(dot(fa_pre_r0, _570), dot(fa_pre_r1, _570), dot(fa_pre_r2, _570)));\n    float _597 = _585.z;\n    float2 e = _585.xy / ((abs(_585.x) + abs(_585.y)) + abs(_597)).xx;\n    if (_597 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_168",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_272",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_233",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 5
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _173_fa_view_proj : packoffset(c0);\n    row_major float4x4 _173_fa_light_vp : packoffset(c4);\n    float4 _173_fa_uv_scale : packoffset(c8);\n    float4 _173_fa_time : packoffset(c9);\n    float4 _173_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _217_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _384_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_217_fa_joint_rows[_208] * weights[i]);\n        r1 += (_217_fa_joint_rows[_208 + 1] * weights[i]);\n        r2 += (_217_fa_joint_rows[_208 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _431 = { mul(float4(position, 1.0f), model).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173_fa_uv_scale.xy, color, position };\n    return _431;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _322 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_322, _173_fa_light_vp).z;\n    fa_pre_r0 = float3(_173_fa_light_vp[0].x, _173_fa_light_vp[1].x, _173_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_173_fa_light_vp[0].y, _173_fa_light_vp[1].y, _173_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_173_fa_light_vp[0].z, _173_fa_light_vp[1].z, _173_fa_light_vp[2].z);\n    gl_Position = mul(_322, _173_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _384_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _233_fa_camera_pos : packoffset(c0);\n    float4 _233_fa_ambient : packoffset(c1);\n    float4 _233_fa_base_color : packoffset(c2);\n    float4 _233_fa_emissive : packoffset(c3);\n    float4 _233_fa_model_emissive : packoffset(c4);\n    float4 _233_fa_pbr : packoffset(c5);\n    float4 _233_fa_maps : packoffset(c6);\n    float4 _233_fa_fog : packoffset(c7);\n    float4 _233_fa_fog_b : packoffset(c8);\n    float4 _233_fa_fog_c : packoffset(c9);\n    float4 _233_fa_counts : packoffset(c10);\n    float4 _233_fa_env_sky : packoffset(c11);\n    float4 _233_fa_env_horizon : packoffset(c12);\n    float4 _233_fa_time : packoffset(c13);\n    float4 _233_fa_cl_vpx : packoffset(c14);\n    float4 _233_fa_cl_vpy : packoffset(c15);\n    float4 _233_fa_cl_vpw : packoffset(c16);\n    float4 _233_fa_cl_fwd : packoffset(c17);\n    float4 _233_fa_cl_grid : packoffset(c18);\n    float4 _233_fa_cl_info : packoffset(c19);\n    float4 _233_fa_layers_a : packoffset(c20);\n    float4 _233_fa_layers_b : packoffset(c21);\n    float4 _233_fa_layers_c : packoffset(c22);\n    float4 _233_fa_layers_d : packoffset(c23);\n    float4 _233_fa_ct_a : packoffset(c24);\n    float4 _233_fa_ct_b : packoffset(c25);\n    float4 _233_fa_ct_vpx : packoffset(c26);\n    float4 _233_fa_ct_vpy : packoffset(c27);\n    float4 _233_fa_ct_vpw : packoffset(c28);\n    float4 _233_fa_ct_fwd : packoffset(c29);\n    float4 _233_fa_tr_a : packoffset(c30);\n    float4 _233_fa_tr_b : packoffset(c31);\n    float4 _233_fa_probe_sh[9] : packoffset(c32);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _233_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _244 = fa_tex_fix(param_2, param_3);\n    float4 _795 = base_t;\n    _795.x = _244.x;\n    _795.y = _244.y;\n    _795.z = _244.z;\n    base_t = _795;\n    float4 _259 = (_795 * _233_fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_233_fa_maps.z > 0.5f)\n    {\n        float param_4 = _233_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _292 = fa_tex_fix(param_6, param_7);\n        float3 _296 = (_292 * 2.0f) - 1.0f.xxx;\n        float2 _301 = _296.xy * _233_fa_maps.x;\n        float3 _803 = _296;\n        _803.x = _301.x;\n        _803.y = _301.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _803;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _233_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _330 = fa_tex_fix(param_12, param_13);\n    float4 _806 = mrt;\n    _806.x = _330.x;\n    _806.y = _330.y;\n    _806.z = _330.z;\n    mrt = _806;\n    float4 _360 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _233_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _360.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _233_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _402 = fa_tex_fix(param_20, param_21);\n    float _755 = _233_fa_layers_a.x;\n    float _756 = _233_fa_layers_a.y;\n    float _759 = _233_fa_layers_a.z;\n    float _758 = _233_fa_layers_b.w;\n    float _761 = _233_fa_layers_c.x;\n    if (_233_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_233_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _755 *= _372.y;\n            _756 *= _372.z;\n            _758 *= _360.w;\n        }\n        if (_233_fa_layers_c.z > 1.5f)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    Surface _788 = { _259.xyz, _259.w, _750, clamp(_233_fa_pbr.x * _330.z, 0.0f, 1.0f), clamp(_233_fa_pbr.y * _330.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_233_fa_maps.y * (_372.x - 1.0f)), _233_fa_emissive.xyz + (_233_fa_model_emissive.xyz * _402), _755, _756, _233_fa_layers_b.xyz, _758, _759, _233_fa_layers_a.w, _761, _233_fa_layers_c.y, _233_fa_layers_d.xyz, _233_fa_tr_a.x, _233_fa_tr_a.y, _233_fa_tr_b.xyz, _233_fa_tr_a.z };\n    return _788;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    float3 _555 = normalize(_233_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _658 = { fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param = _658;\n    SurfaceInput _666 = { fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param_1 = _666;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _570 = normalize(param_2.normal);\n    float3 _585 = normalize(float3(dot(fa_pre_r0, _570), dot(fa_pre_r1, _570), dot(fa_pre_r2, _570)));\n    float _597 = _585.z;\n    float2 e = _585.xy / ((abs(_585.x) + abs(_585.y)) + abs(_597)).xx;\n    if (_597 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_173",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_384",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_233",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 5
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _159_fa_view_proj : packoffset(c0);\n    row_major float4x4 _159_fa_light_vp : packoffset(c4);\n    float4 _159_fa_uv_scale : packoffset(c8);\n    float4 _159_fa_time : packoffset(c9);\n    float4 _159_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _176_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _100 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _100) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_100 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * _159_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _176_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _159_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_159",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_176",
            "hlsl_register_b_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _164_fa_view_proj : packoffset(c0);\n    row_major float4x4 _164_fa_light_vp : packoffset(c4);\n    float4 _164_fa_uv_scale : packoffset(c8);\n    float4 _164_fa_time : packoffset(c9);\n    float4 _164_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _208_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _288_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _199 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_208_fa_joint_rows[_199] * weights[i]);\n        r1 += (_208_fa_joint_rows[_199 + 1] * weights[i]);\n        r2 += (_208_fa_joint_rows[_199 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _105 = cross(model[1].xyz, model[2].xyz);\n    float _110 = (dot(model[0].xyz, _105) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _383 = { mul(float4(position, 1.0f), model).xyz, (((_105 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _110, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _110), texcoord0 * _164_fa_uv_scale.xy, color, position };\n    return _383;\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _288_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _164_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_164",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_208",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_288",
            "hlsl_register_b_n": 6
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          }
        ]
      }
    }
  }
}
