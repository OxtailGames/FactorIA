{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4a8331d4c52f4add9385ad09f3cee754aeec6a52a5c8c810972e182590f5426b",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "extra",
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
    },
    {
      "name": "points",
      "binding": 1,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _182_fa_view_proj : packoffset(c0);\n    row_major float4x4 _182_fa_light_vp : packoffset(c4);\n    float4 _182_fa_uv_scale : packoffset(c8);\n    float4 _182_fa_time : packoffset(c9);\n    float4 _182_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _252_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _293 = { mul(float4(position, 1.0f), model).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * _182_fa_uv_scale.xy, color, position };\n    return _293;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _77;\n    if (!_62)\n    {\n        _77 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _182_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _252_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _4337[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _654_fa_camera_pos : packoffset(c0);\n    float4 _654_fa_ambient : packoffset(c1);\n    float4 _654_fa_base_color : packoffset(c2);\n    float4 _654_fa_emissive : packoffset(c3);\n    float4 _654_fa_model_emissive : packoffset(c4);\n    float4 _654_fa_pbr : packoffset(c5);\n    float4 _654_fa_maps : packoffset(c6);\n    float4 _654_fa_fog : packoffset(c7);\n    float4 _654_fa_fog_b : packoffset(c8);\n    float4 _654_fa_fog_c : packoffset(c9);\n    float4 _654_fa_counts : packoffset(c10);\n    float4 _654_fa_env_sky : packoffset(c11);\n    float4 _654_fa_env_horizon : packoffset(c12);\n    float4 _654_fa_time : packoffset(c13);\n    float4 _654_fa_cl_vpx : packoffset(c14);\n    float4 _654_fa_cl_vpy : packoffset(c15);\n    float4 _654_fa_cl_vpw : packoffset(c16);\n    float4 _654_fa_cl_fwd : packoffset(c17);\n    float4 _654_fa_cl_grid : packoffset(c18);\n    float4 _654_fa_cl_info : packoffset(c19);\n    float4 _654_fa_layers_a : packoffset(c20);\n    float4 _654_fa_layers_b : packoffset(c21);\n    float4 _654_fa_layers_c : packoffset(c22);\n    float4 _654_fa_layers_d : packoffset(c23);\n    float4 _654_fa_ct_a : packoffset(c24);\n    float4 _654_fa_ct_b : packoffset(c25);\n    float4 _654_fa_ct_vpx : packoffset(c26);\n    float4 _654_fa_ct_vpy : packoffset(c27);\n    float4 _654_fa_ct_vpw : packoffset(c28);\n    float4 _654_fa_ct_fwd : packoffset(c29);\n    float4 _654_fa_tr_a : packoffset(c30);\n    float4 _654_fa_tr_b : packoffset(c31);\n    float4 _654_fa_probe_sh[9] : packoffset(c32);\n    float4 _654_fa_atlas : packoffset(c41);\n    float4 _654_fa_rpa_tile : packoffset(c42);\n    float4 _654_fa_rpa_pos : packoffset(c43);\n    float4 _654_fa_rpa_bx : packoffset(c44);\n    float4 _654_fa_rpa_by : packoffset(c45);\n    float4 _654_fa_rpa_bz : packoffset(c46);\n    float4 _654_fa_rpb_tile : packoffset(c47);\n    float4 _654_fa_rpb_pos : packoffset(c48);\n    float4 _654_fa_rpb_bx : packoffset(c49);\n    float4 _654_fa_rpb_by : packoffset(c50);\n    float4 _654_fa_rpb_bz : packoffset(c51);\n    float4 _654_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2321_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2321_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2321_fa_shadow_info[4] : packoffset(c20);\n    float4 _2321_fa_shadow_split : packoffset(c24);\n    float4 _2321_fa_shadow_cfg : packoffset(c25);\n    float4 _2321_fa_shadow_bias : packoffset(c26);\n    float4 _2321_fa_shadow_eye : packoffset(c27);\n    float4 _2321_fa_shadow_fwd : packoffset(c28);\n    float4 _2321_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1592 = _654_fa_cl_info.x < 0.0f;\n    bool _1599;\n    if (!_1592)\n    {\n        _1599 = _654_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1599 = _1592;\n    }\n    bool _1607;\n    if (!_1599)\n    {\n        _1607 = _654_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1607 = _1599;\n    }\n    bool _1614;\n    if (!_1607)\n    {\n        _1614 = _654_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1614 = _1607;\n    }\n    bool _1621;\n    if (!_1614)\n    {\n        _1621 = _654_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1621 = _1614;\n    }\n    if (_1621)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1631 = float4(world_pos, 1.0f);\n    float _1637 = dot(_654_fa_cl_vpw, _1631);\n    if (!(_1637 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1659 = float2(dot(_654_fa_cl_vpx, _1631), dot(_654_fa_cl_vpy, _1631)) / _1637.xx;\n    int _1663 = int(_654_fa_cl_grid.x);\n    int _1667 = int(_654_fa_cl_grid.y);\n    int param = (int(_654_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_654_fa_cl_fwd.xyz, world_pos) + _654_fa_cl_fwd.w, _654_fa_cl_grid.w) / _654_fa_cl_grid.w) * _654_fa_cl_grid.z)), 0, int(_654_fa_cl_info.y) - 1) * _1667) + clamp(int(floor(((_1659.y * 0.5f) + 0.5f) * _654_fa_cl_grid.y)), 0, _1667 - 1)) * _1663)) + clamp(int(floor(((_1659.x * 0.5f) + 0.5f) * _654_fa_cl_grid.x)), 0, _1663 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1743 = fa_cluster_texel(param);\n    return int2(int(_1743.x), int(_1743.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_654_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5798 = fa_cluster_lookup(param);\n    fa_cl_slot = _5798.x;\n    fa_cl_local = _5798.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6946 = fa_linear_to_srgb(param);\n        c = _6946;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6954 = fa_srgb_to_linear(param_1);\n            c = _6954;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _536;\n    if (i.front_facing)\n    {\n        _536 = i.world_normal;\n    }\n    else\n    {\n        _536 = -i.world_normal;\n    }\n    float3 _560 = normalize(i.world_tangent.xyz - (_536 * dot(_536, i.world_tangent.xyz)));\n    float3 _587 = normalize(((_560 * m.x) + ((cross(_536, _560) * i.world_tangent.w) * m.y)) + (_536 * m.z));\n    float3 _590;\n    if (i.front_facing)\n    {\n        _590 = _587;\n    }\n    else\n    {\n        _590 = -_587;\n    }\n    return _590;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _654_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6985 = fa_tex_fix(param_2, param_3);\n    float4 _9183 = base_t;\n    _9183.x = _6985.x;\n    _9183.y = _6985.y;\n    _9183.z = _6985.z;\n    base_t = _9183;\n    float4 _6999 = (_9183 * _654_fa_base_color) * i.vertex_color;\n    float3 _8967 = i.world_normal;\n    if (_654_fa_maps.z > 0.5f)\n    {\n        float param_4 = _654_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7031 = fa_tex_fix(param_6, param_7);\n        float3 _7034 = (_7031 * 2.0f) - 1.0f.xxx;\n        float2 _7039 = _7034.xy * _654_fa_maps.x;\n        float3 _9191 = _7034;\n        _9191.x = _7039.x;\n        _9191.y = _7039.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9191;\n        _8967 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _654_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7067 = fa_tex_fix(param_12, param_13);\n    float4 _9194 = mrt;\n    _9194.x = _7067.x;\n    _9194.y = _7067.y;\n    _9194.z = _7067.z;\n    mrt = _9194;\n    float4 _7095 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _654_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7095.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7106 = fa_tex_fix(param_16, param_17);\n    float param_18 = _654_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7136 = fa_tex_fix(param_20, param_21);\n    float _8972 = _654_fa_layers_a.x;\n    float _8973 = _654_fa_layers_a.y;\n    float _8976 = _654_fa_layers_a.z;\n    float _8975 = _654_fa_layers_b.w;\n    float _8978 = _654_fa_layers_c.x;\n    if (_654_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_654_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _8972 *= _7106.y;\n            _8973 *= _7106.z;\n            _8975 *= _7095.w;\n        }\n        if (_654_fa_layers_c.z > 1.5f)\n        {\n            _8976 *= mrt.x;\n            _8978 *= mrt.w;\n        }\n    }\n    Surface _9005 = { _6999.xyz, _6999.w, _8967, clamp(_654_fa_pbr.x * _7067.z, 0.0f, 1.0f), clamp(_654_fa_pbr.y * _7067.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_654_fa_maps.y * (_7106.x - 1.0f)), _654_fa_emissive.xyz + (_654_fa_model_emissive.xyz * _7136), _8972, _8973, _654_fa_layers_b.xyz, _8975, _8976, _654_fa_layers_a.w, _8978, _654_fa_layers_c.y, _654_fa_layers_d.xyz, _654_fa_tr_a.x, _654_fa_tr_a.y, _654_fa_tr_b.xyz, _654_fa_tr_a.z };\n    return _9005;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1823 = rect.zw - rect.xy;\n    float2 _1827 = _1823 * atlas;\n    float2 _1831 = ddx * _1827;\n    float2 _1835 = ddy * _1827;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1823), clamp(0.5f * log2(max(max(dot(_1831, _1831), dot(_1835, _1835)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1868 = _654_fa_counts.y < 0.5f;\n    bool _1875;\n    if (!_1868)\n    {\n        _1875 = _654_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1875 = _1868;\n    }\n    if (_1875)\n    {\n        return;\n    }\n    float3 _1881 = ddx(world_pos);\n    float3 _1884 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1888 = fa_cluster_texel(param);\n    int _1892 = int(_1888.w);\n    if (_1892 < 1)\n    {\n        return;\n    }\n    int _1902 = int(_654_fa_counts.y + 0.5f);\n    int param_1 = _1902;\n    float4 _1906 = fa_light_texel(param_1);\n    float2 _1909 = _1906.yz;\n    int _1913 = int(_1906.w);\n    int param_2 = _1902 + 1;\n    float4 _1918 = fa_light_texel(param_2);\n    float _1919 = _1918.x;\n    int _1925 = int(_654_fa_counts.w + 0.5f) - 1;\n    int _1929 = int(_1888.z);\n    float3 _2194;\n    for (int k = 0; k < _1892; k++)\n    {\n        int _1942 = _1929 + k;\n        int param_3 = _1913 + (_1942 >> 2);\n        int _1959 = (_1902 + 2) + (int(fa_light_texel(param_3)[_1942 & 3]) * 7);\n        int param_4 = _1959 + 6;\n        float4 _1964 = fa_light_texel(param_4);\n        if (((int(_1964.w + 0.5f) >> _1925) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1959;\n        float4 _1979 = fa_light_texel(param_5);\n        int param_6 = _1959 + 1;\n        float4 _1984 = fa_light_texel(param_6);\n        int param_7 = _1959 + 2;\n        float4 _1989 = fa_light_texel(param_7);\n        float3 _1992 = _1979.xyz;\n        float _1997 = dot(_1992, world_pos) + _1979.w;\n        float3 _1999 = _1984.xyz;\n        float _2004 = dot(_1999, world_pos) + _1984.w;\n        float3 _2006 = _1989.xyz;\n        float _2011 = dot(_2006, world_pos) + _1989.w;\n        bool _2016 = abs(_1997) > 0.5f;\n        bool _2024;\n        if (!_2016)\n        {\n            _2024 = abs(_2004) > 0.5f;\n        }\n        else\n        {\n            _2024 = _2016;\n        }\n        bool _2032;\n        if (!_2024)\n        {\n            _2032 = abs(_2011) > 0.5f;\n        }\n        else\n        {\n            _2032 = _2024;\n        }\n        if (_2032)\n        {\n            continue;\n        }\n        float _2047 = clamp(dot(geo_normal, normalize(_2006)) * _1964.z, 0.0f, 1.0f);\n        if (_2047 <= 0.0f)\n        {\n            continue;\n        }\n        float _2067 = (clamp((0.5f - abs(_2011)) * 10.0f, 0.0f, 1.0f) * _2047) * _1964.x;\n        float2 _2075 = float2(_1997 + 0.5f, 0.5f - _2004);\n        float2 _2085 = float2(dot(_1992, _1881), dot(_1999, _1881));\n        float2 _2095 = float2(dot(_1992, _1884), dot(_1999, _1884));\n        int param_8 = _1959 + 5;\n        float4 _2100 = fa_light_texel(param_8);\n        int param_9 = _1959 + 3;\n        float4 _2105 = fa_light_texel(param_9);\n        int param_10 = _1959 + 4;\n        float4 _2110 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2100.xyz;\n        bool _2120 = _2105.z > _2105.x;\n        if (_2120)\n        {\n            float4 param_11 = _2105;\n            float2 param_12 = _2075;\n            float2 param_13 = _1909;\n            float2 param_14 = _2085;\n            float2 param_15 = _2095;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1919 > 0.5f) && (_1919 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2146 = fa_dc_to_linear(param_16);\n                float4 _9055 = tx;\n                _9055.x = _2146.x;\n                _9055.y = _2146.y;\n                _9055.z = _2146.z;\n                tx = _9055;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2067 * tex_a) * _2100.w, 0.0f, 1.0f).xxx);\n        if (_2110.z > _2110.x)\n        {\n            float4 param_17 = _2110;\n            float2 param_18 = _2075;\n            float2 param_19 = _1909;\n            float2 param_20 = _2085;\n            float2 param_21 = _2095;\n            float4 _2190 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1919 > 1.5f)\n            {\n                float3 param_22 = _2190.xyz;\n                float3 _2200 = fa_dc_to_srgb(param_22);\n                _2194 = _2200;\n            }\n            else\n            {\n                _2194 = _2190.xyz;\n            }\n            float3 _2209 = (_2194 * 2.0f) - 1.0f.xxx;\n            float2 _2214 = _2209.xy * _1964.y;\n            float3 _2236 = (normalize(_1992) * _2214.x) + (normalize(_1999) * _2214.y);\n            float3 _2239 = normalize(normal);\n            normal = normalize(lerp(_2239, normalize((_2239 * max(_2209.z, 0.0500000007450580596923828125f)) + (_2236 - (_2239 * dot(_2239, _2236)))), clamp(_2067 * (_2120 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4263 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4270 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4273 = int(_4263);\n    int _4276 = int(_4270);\n    float _4286 = _4270 - float(_4276);\n    int _4341 = (_4273 * 9) + _4276;\n    int _4361 = ((_4273 + 1) * 9) + _4276;\n    return lerp(lerp(_4337[_4341], _4337[_4341 + 1], _4286), lerp(_4337[_4361], _4337[_4361 + 1], _4286), _4263 - float(_4273));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _8890 = false;\n    float _8891 = 1.0f;\n    float _8892 = 1.0f;\n    float _8893 = 1.0f;\n    float _8894 = 0.0f;\n    float _8895 = 0.0f;\n    float _8896 = 0.0f;\n    float _8897 = 0.0f;\n    float _8899 = 1.0f;\n    bool _8900 = false;\n    float3 _8901 = 0.0f.xxx;\n    float _8902 = 1.0f;\n    float _8903 = 1.0f;\n    float _8904 = 1.0f;\n    float _8905 = 0.0f;\n    float _8906 = 0.0f;\n    float3 _8907 = float3(1.0f, 0.0f, 0.0f);\n    float3 _8908 = float3(0.0f, 0.0f, 1.0f);\n    float _8909 = 1.0f;\n    float _8910 = 1.0f;\n    float _4412 = clamp(s.specular, 0.0f, 1.0f);\n    float _4416 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4421 = (_4412 != 1.0f) || (_4416 != 1.5f);\n    bool _4430;\n    if (!_4421)\n    {\n        _4430 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4430 = _4421;\n    }\n    if (_4430)\n    {\n        float _4438 = (_4416 - 1.0f) / (_4416 + 1.0f);\n        f0 = lerp(min((_4438 * _4438).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4412, s.albedo, metallic.xxx);\n        _8891 = lerp(_4412, 1.0f, metallic);\n        _8890 = true;\n    }\n    float _4465 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4465 > 0.0f)\n    {\n        float _4473 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _8894 = _4465;\n        _8895 = _4473;\n        float _4480 = _4473 * _4473;\n        _8896 = _4480;\n        _8897 = _4480 * _4480;\n        float _4492 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _8899 = _4492;\n        _8892 = 1.0f - (_4465 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4492, 0.0f, 1.0f), 5.0f))));\n        _8890 = true;\n    }\n    float3 _4511 = max(s.sheen_color, 0.0f.xxx);\n    float _4520 = max(_4511.x, max(_4511.y, _4511.z));\n    if (_4520 > 0.0f)\n    {\n        float _4528 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _8900 = true;\n        _8901 = _4511;\n        _8902 = _4528;\n        _8903 = _4528 * _4528;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4528;\n        float _4545 = fa_sheen_albedo(param, param_1);\n        _8905 = _4545;\n        _8904 = 1.0f - min(_4520 * _4545, 1.0f);\n        _8890 = true;\n    }\n    _8893 = _8892 * _8904;\n    float _4564 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4564 != 0.0f)\n    {\n        float3 _4579 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4579;\n        if (dot(_4579, _4579) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4591 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4591.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4591.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4591.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4595 = t;\n        float3 _4596 = normalize(_4595);\n        t = _4596;\n        float3 _4621 = normalize((_4596 * cos(s.anisotropy_rotation)) + ((cross(n, _4596) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _8907 = _4621;\n        _8908 = cross(n, _4621);\n        float _4631 = roughness * roughness;\n        float _4637 = lerp(_4631, 1.0f, _4564 * _4564);\n        bool _4639 = _4564 > 0.0f;\n        _8909 = _4639 ? _4637 : _4631;\n        _8910 = _4639 ? _4631 : _4637;\n        _8906 = _4564;\n        _8890 = true;\n    }\n    FaLayers _8932 = { _8890, _8891, _8892, _8893, _8894, _8895, _8896, _8897, i.world_normal, _8899, _8900, _8901, _8902, _8903, _8904, _8905, _8906, _8907, _8908, _8909, _8910 };\n    return _8932;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3434 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3434;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3493_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3493_dummy_parameter)));\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3454 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3457 = _3454.x;\n    float _3459 = _3454.z;\n    float2 e = float2(_3457, _3459);\n    if (_3454.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3459)) * ((_3457 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3457)) * ((_3459 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7246 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7251 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7256 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7261 = fa_light_texel(param_3);\n    bool _7264 = _7261.z < 0.5f;\n    bool _7272;\n    if (!_7264)\n    {\n        _7272 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7272 = _7264;\n    }\n    if (_7272)\n    {\n        return 0.0f.xxx;\n    }\n    float _7279 = max(_7246.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7282 = _7251.xyz;\n    float3 _7286 = _7246.xyz;\n    float3 _7290 = (fa_world_pos - _7286) / _7279.xxx;\n    float3 _7299 = min(_7290 + 0.5f.xxx, (_7282 - 0.5f.xxx) - _7290);\n    float _7308 = min(_7299.x, min(_7299.y, _7299.z));\n    if (!(_7308 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7323 = _7282 - 1.0f.xxx;\n    float3 _7324 = clamp(_7290, 0.0f.xxx, _7323);\n    float3 _7332 = min(floor(_7324), max(_7282 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7336 = _7324 - _7332;\n    float3 _7347 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7279));\n    int _7352 = int(_7256.y + 0.5f);\n    float3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = 0.0f.xxx;\n    }\n    float wsum = 0.0f;\n    int _7370 = int(_7261.w);\n    int _7371 = 8 + _7370;\n    int _7376 = 9 + _7370;\n    float _7403;\n    float _7416;\n    float _7430;\n    for (int k_1 = 0; k_1 < _7371; k_1++)\n    {\n        float _7389 = float(k_1 & 1);\n        float _7393 = float((k_1 >> 1) & 1);\n        float _7397 = float((k_1 >> 2) & 1);\n        if (_7389 > 0.5f)\n        {\n            _7403 = _7336.x;\n        }\n        else\n        {\n            _7403 = 1.0f - _7336.x;\n        }\n        if (_7393 > 0.5f)\n        {\n            _7416 = _7336.y;\n        }\n        else\n        {\n            _7416 = 1.0f - _7336.y;\n        }\n        if (_7397 > 0.5f)\n        {\n            _7430 = _7336.z;\n        }\n        else\n        {\n            _7430 = 1.0f - _7336.z;\n        }\n        float _7440 = (_7403 * _7416) * _7430;\n        if (!(_7440 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7453 = min(_7332 + float3(_7389, _7393, _7397), _7323);\n        int _7473 = int(((_7256.x + _7453.x) + (_7251.x * (_7453.y + (_7251.y * _7453.z)))) + 0.5f);\n        float2 _7488 = float2(float(_7473 % _7352) * 10.0f, 1024.0f + (float(_7473 / _7352) * 11.0f));\n        float2 param_4 = _7488 + float2(9.5f, 10.5f);\n        float4 _7496 = fa_gi_fetch(param_4);\n        bool _7499 = _7496.y < 0.5f;\n        bool _7508;\n        if (!_7499)\n        {\n            _7508 = _7496.x > _7261.y;\n        }\n        else\n        {\n            _7508 = _7499;\n        }\n        if (_7508)\n        {\n            continue;\n        }\n        float3 _7520 = _7347 - (_7286 + (_7453 * _7279));\n        float _7523 = length(_7520);\n        float3 _7529 = _7520 / max(_7523, 9.9999997473787516355514526367188e-05f).xxx;\n        float _7539 = max(9.9999997473787516355514526367188e-05f, (dot(-_7529, n) + 1.0f) * 0.5f);\n        float w = _7440 * (_7539 * _7539);\n        float3 param_5 = _7529;\n        float2 param_6 = (_7488 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _7558 = fa_gi_fetch(param_6);\n        float _7565 = _7523 / max(_7256.z, 9.9999997473787516355514526367188e-05f);\n        float _7568 = _7558.x;\n        if (_7565 > _7568)\n        {\n            float _7581 = max(_7558.y - (_7568 * _7568), 0.0f);\n            float _7586 = _7565 - _7568;\n            float _7595 = _7581 / max(_7581 + (_7586 * _7586), 9.9999999600419720025001879548654e-13f);\n            w *= ((_7595 * _7595) * _7595);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        for (int c = 0; c < _7376; c++)\n        {\n            float2 param_7 = _7488 + float2(float(c) + 0.5f, 10.5f);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= wsum.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7308 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _7676;\n    if (_654_fa_gi.z > 0.5f)\n    {\n        _7676 = _7261.x;\n    }\n    else\n    {\n        _7676 = 1.0f;\n    }\n    float3 param_8[9] = sh;\n    float3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_7256.w * _7676);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _7700 = normalize(_654_fa_camera_pos.xyz - fa_world_pos);\n    int _7705 = int(_654_fa_gi.x + 0.5f);\n    int _7710 = int(_654_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _7710) && (k < 8); k++)\n    {\n        int param = _7705 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _7700;\n        float3 _7735 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7740 = param_3 * left;\n        acc += (_7735 * _7740);\n        left -= _7740;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_654_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4044 = (1.0f - _654_fa_rpa_tile.w) - _654_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4049 = _654_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4044 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4049)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _654_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4044;\n            }\n        }\n        else\n        {\n            amb = _654_fa_ambient.xyz * _4044;\n        }\n    }\n    bool _4100 = _654_fa_rpa_tile.w > 0.0f;\n    if (_4100)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _654_fa_rpa_tile.xy;\n            float param_4 = _654_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _654_fa_rpa_tile.w);\n        }\n    }\n    bool _4131 = _654_fa_rpb_tile.w > 0.0f;\n    if (_4131)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _654_fa_rpb_tile.xy;\n            float param_7 = _654_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _654_fa_rpb_tile.w);\n        }\n    }\n    if ((_4049 || _4100) || _4131)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    if (_654_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _7769 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375f)\n        {\n            float3 _7777;\n            if (param_1 > 0.0f)\n            {\n                float3 param_2 = n;\n                _7777 = _7769 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _7777 = _7769;\n            }\n            return _7777;\n        }\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_654_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _654_fa_probe_sh[k].xyz;\n        }\n        float3 param[9] = c;\n        float3 param_1 = n;\n        float3 _7839 = fa_sh_eval(param, param_1);\n        if (_654_fa_probe_sh[0].w >= 1.0f)\n        {\n            return _7839;\n        }\n        float3 param_2 = n;\n        return lerp(fa_realtime_or_ambient(param_2), _7839, clamp(_654_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_654_fa_cl_info.x) + int(_654_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_654_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5768;\n    if (fa_lm.z > 0.5f)\n    {\n        _5768 = 0.0f;\n    }\n    else\n    {\n        _5768 = 1.0f - clamp(_654_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5779 = _5768 < 1.0f;\n    bool _5785;\n    if (_5779)\n    {\n        int param = li;\n        _5785 = fa_light_baked(param);\n    }\n    else\n    {\n        _5785 = _5779;\n    }\n    return _5785 ? _5768 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _722_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _722_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _841 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _854 = (c - (ru * hx)) - p;\n        float3 _860 = ru * (2.0f * hx);\n        float _866 = max(dot(_860, _860), 9.9999999392252902907785028219223e-09f);\n        float _870 = dot(_854, _860);\n        float t = clamp((-_870) / _866, 0.0f, 1.0f);\n        if (_841)\n        {\n            float _885 = dot(r, _860);\n            float _891 = _866 - (_885 * _885);\n            if (abs(_891) > (9.9999997473787516355514526367188e-06f * _866))\n            {\n                t = clamp(((dot(r, _854) * _885) - _870) / _891, 0.0f, 1.0f);\n            }\n        }\n        return (p + _854) + (_860 * t);\n    }\n    float3 q = p;\n    float _923 = dot(r, axis);\n    bool _931;\n    if (_841)\n    {\n        _931 = abs(_923) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _931 = _841;\n    }\n    if (_931)\n    {\n        float _941 = dot(c - p, axis) / _923;\n        if (_941 > 0.0f)\n        {\n            q = p + (r * _941);\n        }\n    }\n    float3 _954 = q - c;\n    float2 xy = float2(dot(_954, ru), dot(_954, uu));\n    if (shape > 0.5f)\n    {\n        float _969 = length(xy);\n        if (_969 > hx)\n        {\n            xy *= (hx / _969);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _602 = abs(d);\n    float _604 = _602.x;\n    float _606 = _602.y;\n    bool _607 = _604 >= _606;\n    bool _615;\n    if (_607)\n    {\n        _615 = _604 >= _602.z;\n    }\n    else\n    {\n        _615 = _607;\n    }\n    int _616;\n    if (_615)\n    {\n        _616 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _631;\n        if (_606 >= _602.z)\n        {\n            _631 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _631 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _616 = _631;\n    }\n    return _616;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _761 = dot(d, right);\n    float _765 = dot(d, up);\n    float _776;\n    if (((_761 * _761) + (_765 * _765)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _776 = atan2(_765, _761) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _776 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_776 - floor(_776)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1007 = fa_light_base(param);\n    bool _1011 = _654_fa_ambient.w > 4.5f;\n    int param_1 = _1007;\n    float4 _1015 = fa_light_texel(param_1);\n    int param_2 = _1007 + 1;\n    float4 _1020 = fa_light_texel(param_2);\n    float _1023 = _1020.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1035 = _1011 && (_1023 > 2.5f);\n    fa_light_is_area = _1035;\n    bool _1037 = _1023 < 0.5f;\n    float3 l;\n    if (_1037)\n    {\n        l = normalize(_1015.xyz);\n        if (_1011)\n        {\n            int param_3 = _1007 + 6;\n            float4 _1051 = fa_light_texel(param_3);\n            if (_1051.z > 0.5f)\n            {\n                int param_4 = _1007 + 4;\n                float4 _1061 = fa_light_texel(param_4);\n                int param_5 = _1007 + 5;\n                float4 _1066 = fa_light_texel(param_5);\n                float2 param_6 = _1051.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1061.xyz) * _1061.w, (-dot(world_pos, _1066.xyz)) * _1066.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1096 = _1015.xyz;\n        float3 _1098 = _1096 - world_pos;\n        float3 to_light = _1098;\n        float _1101 = length(_1098);\n        float reach = _1101;\n        bool front = true;\n        if (_1035)\n        {\n            int param_8 = _1007 + 7;\n            reach = max(_1101 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1007 + 4;\n            float4 _1125 = fa_light_texel(param_9);\n            int param_10 = _1007 + 5;\n            float4 _1130 = fa_light_texel(param_10);\n            int param_11 = _1007 + 6;\n            float4 _1135 = fa_light_texel(param_11);\n            float _1136 = _1135.w;\n            int param_12 = _1007 + 2;\n            float3 _1143 = normalize(fa_light_texel(param_12).xyz);\n            bool _1145 = _1136 > 1.5f;\n            bool _1153;\n            if (!_1145)\n            {\n                _1153 = dot(_1143, to_light) < 0.0f;\n            }\n            else\n            {\n                _1153 = _1145;\n            }\n            front = _1153;\n            float3 r = 0.0f.xxx;\n            float3 _1162 = _654_fa_camera_pos.xyz - world_pos;\n            bool _1166 = dot(n, n) > 0.5f;\n            bool _1174;\n            if (_1166)\n            {\n                _1174 = dot(_1162, _1162) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1174 = _1166;\n            }\n            if (_1174)\n            {\n                r = reflect(-normalize(_1162), normalize(n));\n            }\n            float3 param_13 = _1096;\n            float3 param_14 = _1143;\n            float3 param_15 = _1125.xyz;\n            float3 param_16 = _1130.xyz;\n            float param_17 = _1125.w;\n            float param_18 = _1130.w;\n            float param_19 = _1136;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1210 = length(to_light);\n        dist = _1210;\n        l = to_light / max(_1210, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1224 = reach / max(_1015.w, 0.001000000047497451305389404296875f);\n        float _1230 = clamp(1.0f - (_1224 * _1224), 0.0f, 1.0f);\n        float _1232;\n        if (front)\n        {\n            _1232 = _1230 * _1230;\n        }\n        else\n        {\n            _1232 = 0.0f;\n        }\n        atten = _1232;\n        bool _1243 = _1023 < 2.5f;\n        if ((_1023 > 1.5f) && _1243)\n        {\n            int param_22 = _1007 + 2;\n            float4 _1251 = fa_light_texel(param_22);\n            float _1261 = _1251.w;\n            int param_23 = _1007 + 3;\n            float4 _1266 = fa_light_texel(param_23);\n            float _1267 = _1266.x;\n            float cos_inner = _1267;\n            if (_1267 > 1.5f)\n            {\n                cos_inner = lerp(_1261, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1261, cos_inner, dot(-l, normalize(_1251.xyz)));\n        }\n        if (_1011 && (_1023 < 1.5f))\n        {\n            int param_24 = _1007 + 6;\n            float4 _1291 = fa_light_texel(param_24);\n            if (_1291.z > 0.5f)\n            {\n                float3 _1299 = -to_light;\n                int param_25 = _1007 + 4;\n                int param_26 = _1007 + 5;\n                float3 _1313 = fa_light_texel(param_25).xyz;\n                float3 _1317 = fa_light_texel(param_26).xyz;\n                float3 _1326 = float3(dot(_1299, _1313), dot(_1299, _1317), dot(_1299, cross(_1313, _1317)));\n                float3 param_27 = _1326;\n                int _1330 = fa_cube_face(param_27);\n                int param_28 = _1330;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1357 = float2(dot(_1326, cross(param_29, param_30)), dot(_1326, param_30)) / max(dot(_1326, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1361 = _1330 / 3;\n                float2 param_31 = _1291.xy + (float2(float(_1330 - (_1361 * 3)), float(_1361)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1357.x), 0.5f - (0.5f * _1357.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1007 + 7;\n            float4 _1391 = fa_light_texel(param_33);\n            if (_1391.z > 0.5f)\n            {\n                int param_34 = _1007 + 2;\n                int param_35 = _1007 + 4;\n                int param_36 = _1007 + 5;\n                float2 param_37 = _1391.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1011 && _1243)\n            {\n                int param_42 = _1007 + 6;\n                float4 _1438 = fa_light_texel(param_42);\n                int param_43 = _1007 + 7;\n                float4 _1443 = fa_light_texel(param_43);\n                bool _1446 = _1438.z > 0.5f;\n                bool _1453;\n                if (!_1446)\n                {\n                    _1453 = _1443.z > 0.5f;\n                }\n                else\n                {\n                    _1453 = _1446;\n                }\n                if (_1453)\n                {\n                    int param_44 = _1007 + 2;\n                    float4 _1460 = fa_light_texel(param_44);\n                    float3 _1464 = normalize(_1460.xyz);\n                    int param_45 = _1007 + 4;\n                    float4 _1469 = fa_light_texel(param_45);\n                    int param_46 = _1007 + 5;\n                    float4 _1474 = fa_light_texel(param_46);\n                    if (_1446)\n                    {\n                        float3 _1482 = -to_light;\n                        float _1489 = _1460.w;\n                        float _1505 = 0.5f / max(dot(_1482, _1464) * (sqrt(max(1.0f - (_1489 * _1489), 0.0f)) / max(_1489, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1438.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1482, _1469.xyz) * _1505), 0.5f - (dot(_1482, _1474.xyz) * _1505));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1443.z > 0.5f)\n                    {\n                        float2 param_49 = _1443.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1464;\n                        float3 param_52 = _1469.xyz;\n                        float3 param_53 = _1474.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _8878 = _1020.xyz * atten;\n    if (_1011)\n    {\n        _8878 *= fa_light_tint;\n    }\n    int _1574;\n    if (_1037)\n    {\n        _1574 = 0;\n    }\n    else\n    {\n        _1574 = ((_1023 > 1.5f) && (_1023 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _8889 = { l, _8878, atten, 1.0f, dist, _1574 };\n    return _8889;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2311;\n    if (i == 0)\n    {\n        _2311 = _2321_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2327;\n        if (i == 1)\n        {\n            _2327 = _2321_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2335;\n            if (i == 2)\n            {\n                _2335 = _2321_fa_shadow_split.z;\n            }\n            else\n            {\n                _2335 = _2321_fa_shadow_split.w;\n            }\n            _2327 = _2335;\n        }\n        _2311 = _2327;\n    }\n    return _2311;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2368 = fa_shadow_depth(param, param_1);\n    float _2372;\n    if (conv.x < 0.5f)\n    {\n        _2372 = _2368;\n    }\n    else\n    {\n        _2372 = (conv.y * conv.z) / (conv.z - (_2368 * (conv.z - conv.y)));\n    }\n    return _2372;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2299 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2299), sin(_2299)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2418 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2427;\n        if (k < 0.0f)\n        {\n            _2427 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2427 = k;\n        }\n        float _2447 = clamp((_2427 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2418;\n            float2 _2466 = fa_shadow_vogel(param_3, param_4, param_5) * _2447;\n            float2 param_6 = uv + (_2466 * _2321_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2478 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2478 < (zr - (length(_2466) * plane)))\n            {\n                sum += _2478;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0f)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0f) * unit) * _2514) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2536 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2536; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2536;\n        float param_11 = _2418;\n        float2 _2555 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2555 * _2321_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2555) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2536);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2597 = max(_2321_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2602 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2608 = sqrt(1.0f - (_2602 * _2602));\n    float _2615 = min(_2608 / max(_2602, 0.20000000298023223876953125f), 4.0f);\n    float _2620;\n    if (_2321_fa_shadow_bias.y > 0.0f)\n    {\n        _2620 = _2321_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2620 = 1.5f * _2321_fa_shadow_info[ci].x;\n    }\n    float4 _2645 = mul(float4(world + (n * (_2620 * _2608)), 1.0f), _2321_fa_shadow_mat[ci]);\n    float _2652 = _2645.x;\n    bool _2655 = _2652 < _2321_fa_shadow_rect[ci].x;\n    bool _2664;\n    if (!_2655)\n    {\n        _2664 = _2652 > _2321_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2664 = _2655;\n    }\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2645.y < _2321_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2645.y > _2321_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2689;\n    if (!_2682)\n    {\n        _2689 = _2645.z > 1.0f;\n    }\n    else\n    {\n        _2689 = _2682;\n    }\n    if (_2689)\n    {\n        return -1.0f;\n    }\n    float _2697;\n    if (_2321_fa_shadow_bias.x > 0.0f)\n    {\n        _2697 = _2321_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2697 = 1.5f * _2321_fa_shadow_info[ci].x;\n    }\n    float2 param = _2645.xy;\n    float4 param_1 = _2321_fa_shadow_rect[ci];\n    float param_2 = _2645.z - ((_2697 * (1.0f + (0.5f * _2615))) / _2597);\n    float param_3 = _2321_fa_shadow_info[ci].x;\n    float param_4 = _2597;\n    float param_5 = _2597 * 0.25f;\n    float param_6 = ((_2321_fa_shadow_info[ci].x * min(_2615, 3.0f)) * 0.5f) / _2597;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2321_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2321_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_654_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3075 = int(_2321_fa_shadow_cfg.x + 0.5f);\n    if (_3075 < 1)\n    {\n        return 1.0f;\n    }\n    float _3090 = dot(world - _2321_fa_shadow_eye.xyz, _2321_fa_shadow_fwd.xyz);\n    int param = _3075 - 1;\n    if (_3090 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3102 = _3075 > 1;\n    bool _3109;\n    if (_3102)\n    {\n        _3109 = _3090 > _2321_fa_shadow_split.x;\n    }\n    else\n    {\n        _3109 = _3102;\n    }\n    if (_3109)\n    {\n        ci = 1;\n    }\n    bool _3113 = _3075 > 2;\n    bool _3120;\n    if (_3113)\n    {\n        _3120 = _3090 > _2321_fa_shadow_split.y;\n    }\n    else\n    {\n        _3120 = _3113;\n    }\n    if (_3120)\n    {\n        ci = 2;\n    }\n    bool _3124 = _3075 > 3;\n    bool _3131;\n    if (_3124)\n    {\n        _3131 = _3090 > _2321_fa_shadow_split.z;\n    }\n    else\n    {\n        _3131 = _3124;\n    }\n    if (_3131)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3075)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3157 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3157;\n        if (_3157 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2321_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3182;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3182 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3182 = _2321_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3201 = _2321_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3182, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3212 = clamp((_3090 - (fa_shadow_split_at(param_7) - _3201)) / _3201, 0.0f, 1.0f);\n        if (_3212 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3075)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3233 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3233;\n                if (_3233 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3212);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2755 = _654_fa_pbr.z < 0.5f;\n    bool _2762;\n    if (!_2755)\n    {\n        _2762 = _2321_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2762 = _2755;\n    }\n    if (_2762)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2321_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2775 = fa_light_texel(param);\n    float _2776 = _2775.x;\n    if (_2776 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2785 = int(_2776 + 0.5f);\n    int param_1 = _2785;\n    float4 _2789 = fa_light_texel(param_1);\n    int param_2 = _2785 + 1;\n    float4 _2794 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2797 = _2789.y;\n    if (_2797 > 0.0f)\n    {\n        float _2814 = 1.0f - smoothstep(0.75f * _2797, _2797, length(world - _2321_fa_shadow_eye.xyz));\n        fade = _2814;\n        if (_2814 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2789.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2838 = (_2785 + 2) + (face * 6);\n    int param_4 = _2838;\n    int param_5 = _2838 + 1;\n    int param_6 = _2838 + 3;\n    float4 _2852 = fa_light_texel(param_6);\n    int param_7 = _2838 + 4;\n    float4 _2857 = fa_light_texel(param_7);\n    int param_8 = _2838 + 5;\n    float4 _2862 = fa_light_texel(param_8);\n    float _2874 = _2862.x * max(dot(_2852, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2879 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2902 = clamp(dot(n, _2852.xyz), -1.0f, 1.0f);\n    float _2921 = min(sqrt(1.0f - (_2902 * _2902)) / max(abs(dot(n, world - lpos)) / max(dot(_2852, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2924 = _2794.y;\n    float _2926;\n    if (_2924 > 0.0f)\n    {\n        _2926 = _2924;\n    }\n    else\n    {\n        _2926 = 1.5f * _2874;\n    }\n    float4 _2946 = float4(world + (n * (_2926 * sqrt(1.0f - (_2879 * _2879)))), 1.0f);\n    float _2950 = dot(_2852, _2946);\n    float _2953 = _2862.y;\n    if (_2950 < _2953)\n    {\n        return 1.0f;\n    }\n    float2 _2968 = float2(dot(fa_light_texel(param_4), _2946), dot(fa_light_texel(param_5), _2946)) / _2950.xx;\n    float _2970 = _2968.x;\n    bool _2973 = _2970 < _2857.x;\n    bool _2982;\n    if (!_2973)\n    {\n        _2982 = _2970 > _2857.z;\n    }\n    else\n    {\n        _2982 = _2973;\n    }\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2968.y < _2857.y;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2968.y > _2857.w;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    if (_3000)\n    {\n        return 1.0f;\n    }\n    float _3006 = _2794.x;\n    float _3008;\n    if (_3006 > 0.0f)\n    {\n        _3008 = _3006;\n    }\n    else\n    {\n        _3008 = 1.5f * _2874;\n    }\n    float2 param_9 = _2968;\n    float4 param_10 = _2857;\n    float param_11 = _2950 - (_3008 * (1.0f + (0.5f * _2921)));\n    float param_12 = _2874;\n    float param_13 = 1.0f;\n    float param_14 = _2862.z * 0.25f;\n    float param_15 = (_2874 * min(_2921, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2953, _2862.z);\n    int param_17 = int(_2789.z + 0.5f);\n    float param_18 = _2789.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5149 = _654_fa_ct_a.x < 0.5f;\n    bool _5156;\n    if (!_5149)\n    {\n        _5156 = _2321_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5156 = _5149;\n    }\n    if (_5156)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2321_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5169 = fa_light_texel(param);\n    float _5170 = _5169.y;\n    float len = _5170;\n    if (_5170 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5182 = length(world - _654_fa_camera_pos.xyz);\n    float _5192 = 1.0f - smoothstep(0.5f * _654_fa_ct_b.x, _654_fa_ct_b.x, _5182);\n    if (_5192 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5198 = len;\n    float _5201 = min(_5198, 0.89999997615814208984375f * dist);\n    len = _5201;\n    float _5206 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5182);\n    float _5211 = _5206 + (0.5f * _5201);\n    float3 _5217 = world + (gn * _5206);\n    float _5219 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5283;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5234 = (float(k) + _5219) * 0.083333335816860198974609375f;\n        float3 _5242 = _5217 + (l * (_5234 * len));\n        float4 _5248 = float4(_5242, 1.0f);\n        float _5254 = dot(_654_fa_ct_vpw, _5248);\n        if (_5254 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5274 = float2(dot(_654_fa_ct_vpx, _5248), dot(_654_fa_ct_vpy, _5248)) / _5254.xx;\n        float _5278 = _5274.x * 0.5f;\n        float _5279 = _5278 + 0.5f;\n        if (_654_fa_ct_a.y > 0.5f)\n        {\n            _5283 = (_5274.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5283 = 0.5f - (_5274.y * 0.5f);\n        }\n        bool _5299 = _5279 < 0.0f;\n        bool _5306;\n        if (!_5299)\n        {\n            _5306 = _5279 >= 1.0f;\n        }\n        else\n        {\n            _5306 = _5299;\n        }\n        bool _5313;\n        if (!_5306)\n        {\n            _5313 = _5283 < 0.0f;\n        }\n        else\n        {\n            _5313 = _5306;\n        }\n        bool _5320;\n        if (!_5313)\n        {\n            _5320 = _5283 >= 1.0f;\n        }\n        else\n        {\n            _5320 = _5313;\n        }\n        if (_5320)\n        {\n            break;\n        }\n        float4 _5339 = fa_screen_tex.Load(int3(int2(float2(_5279, _5283) * _654_fa_ct_a.zw), 0));\n        if (_5339.w < 0.5f)\n        {\n            continue;\n        }\n        float _5358 = (dot(_654_fa_ct_fwd.xyz, _5242) + _654_fa_ct_fwd.w) - _5339.x;\n        if ((_5358 > _5206) && (_5358 < _5211))\n        {\n            occ = max(occ, (1.0f - (_5234 * _5234)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5279, 0.5f - _5278), min(_5283, 1.0f - _5283))));\n        }\n    }\n    return 1.0f - (occ * _5192);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5824 = fa_baked_keep(param);\n    if (_5824 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _8945 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _8945;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5850 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _8947 = _5850.color;\n    float _8948 = _5850.attenuation;\n    float _8949 = _5850.shadow;\n    bool _5853 = _5850.type == 0;\n    if (_5853 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5850.direction;\n        float _5864 = fa_shadow_factor(param_5, param_6);\n        _8949 = _5864;\n        _8947 *= _5864;\n    }\n    else\n    {\n        bool _5875 = _5850.type != 0;\n        bool _5881;\n        if (_5875)\n        {\n            _5881 = _8948 > 0.0f;\n        }\n        else\n        {\n            _5881 = _5875;\n        }\n        if (_5881)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5850.direction;\n            float _5900 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8949 = _5900;\n            _8947 *= _5900;\n        }\n    }\n    bool _5910 = _654_fa_ct_a.x > 0.5f;\n    bool _5916;\n    if (_5910)\n    {\n        _5916 = _8948 > 0.0f;\n    }\n    else\n    {\n        _5916 = _5910;\n    }\n    if (_5916)\n    {\n        float _5923;\n        if (_5853)\n        {\n            _5923 = 1000000000.0f;\n        }\n        else\n        {\n            _5923 = _5850._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5850.direction;\n        float param_18 = _5923;\n        float _5941 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8949 *= _5941;\n        _8947 *= _5941;\n    }\n    float _5954 = _8948;\n    float _5955 = _5954 * _5824;\n    _8948 = _5955;\n    float3 _5959 = _8947;\n    float3 _5960 = _5959 * _5824;\n    _8947 = _5960;\n    LightSample _8964 = { _5850.direction, _5960, _5955, _8949, _5850._distance, _5850.type };\n    return _8964;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5994 = v - (n * dot(v, n));\n    float3 t = _5994;\n    float _5998 = dot(_5994, _5994);\n    float l2 = _5998;\n    if (_5998 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6008;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6008 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6008 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6008;\n        l2 = dot(_6008, _6008);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6043 = dot(a, a);\n    float _6047 = dot(b, b);\n    if ((_6043 < 1.0000000195414813782625560981111e-24f) || (_6047 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6061 = a * rsqrt(_6043);\n    float3 _6066 = b * rsqrt(_6047);\n    float _6070 = dot(_6061, _6066);\n    float _6073 = abs(_6070);\n    float g = (((((((((((0.0416471660137176513671875f * _6073) - 0.1924748718738555908203125f) * _6073) + 0.4179156124591827392578125f) * _6073) - 0.616057217121124267578125f) * _6073) + 0.777722418308258056640625f) * _6073) - 0.999542415142059326171875f) * _6073) + 1.570791721343994140625f;\n    if (_6070 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6070 * _6070), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6061, _6066) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6130 = a.z > 0.0f;\n    bool _6134 = b.z > 0.0f;\n    if (_6130 && _6134)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6130 != _6134)\n        {\n            float3 _6169 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6169.z = 0.0f;\n            if (_6130)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6169;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6169;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6169;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6169;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6218 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6244 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6270 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6296 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6218;\n    float3 param_1 = _6244;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6244;\n    float3 param_7 = _6270;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6270;\n    float3 param_13 = _6296;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6296;\n    float3 param_19 = _6218;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6445 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6469 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6485 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6445;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6469;\n    float4 param_9 = m;\n    float3 param_10 = _6445;\n    float3 param_11 = _6469;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6485;\n    float4 param_14 = m;\n    float3 param_15 = _6445;\n    float3 param_16 = _6485;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6543 = fa_light_base(param);\n    int param_1 = _6543;\n    int param_2 = _6543 + 1;\n    int param_3 = _6543 + 2;\n    int param_4 = _6543 + 4;\n    float4 _6565 = fa_light_texel(param_4);\n    int param_5 = _6543 + 5;\n    float4 _6570 = fa_light_texel(param_5);\n    int param_6 = _6543 + 6;\n    float4 _6575 = fa_light_texel(param_6);\n    float _6576 = _6575.w;\n    float3 _6581 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6583 = _6576 < 1.5f;\n    bool _6590;\n    if (_6583)\n    {\n        _6590 = dot(normalize(fa_light_texel(param_3).xyz), _6581) >= 0.0f;\n    }\n    else\n    {\n        _6590 = _6583;\n    }\n    if (_6590)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6599 = (_6576 > 0.5f) && _6583;\n    float _6603 = _6599 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6606 = _6565.xyz;\n    float _6608 = _6565.w;\n    float3 _6614 = _6570.xyz;\n    float _6616 = _6570.w;\n    float3 up = _6614 * (_6616 * _6603);\n    float _6622;\n    if (_6599)\n    {\n        _6622 = (3.1415927410125732421875f * _6608) * _6608;\n    }\n    else\n    {\n        _6622 = (4.0f * _6608) * _6616;\n    }\n    if (_6576 > 1.5f)\n    {\n        float3 _6648 = cross(_6606, -_6581);\n        float3 perp = _6648;\n        float _6652 = dot(_6648, _6648);\n        float3 _6655;\n        if (_6652 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6655 = perp * rsqrt(_6652);\n        }\n        else\n        {\n            _6655 = _6614;\n        }\n        perp = _6655;\n        up = _6655 * _6616;\n    }\n    float _6676 = max(_6622, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6686 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6686;\n    float3 param_10 = n;\n    float3 param_11 = _6581;\n    float3 _6694 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6686;\n    float3 param_13 = n;\n    float3 param_14 = _6606 * (_6608 * _6603);\n    float3 _6702 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6686;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6710 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6576;\n    float3 param_20 = _6694;\n    float3 param_21 = _6702;\n    float3 param_22 = _6710;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6729 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6729;\n    float2 param_26 = _6729 + float2(64.0f, 0.0f);\n    float4 _6739 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6576;\n    float3 param_29 = _6694;\n    float3 param_30 = _6702;\n    float3 param_31 = _6710;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6739.x) + ((f90.xxx - f0) * _6739.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6581, _6581)) + _6676) / _6676) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4886 = 1.0f / alpha;\n    return ((2.0f + _4886) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4886)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4921 = max(dot(L.nc, l), 0.0f);\n    float _4927 = max(dot(L.nc, h), 0.0f);\n    float _4936 = ((_4927 * _4927) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4936) * _4936)) * (0.5f / max(lerp((2.0f * _4921) * L.coat_ndv, _4921 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4921)) * _4921;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6807;\n    if (L.sheen_on)\n    {\n        _6807 = L.sheen_scale;\n    }\n    else\n    {\n        _6807 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6807);\n    float3 _6820 = normalize(l + v);\n    int param_10 = li;\n    float3 _6831 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6840 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6820), 0.0f);\n        float param_13 = _6840;\n        float param_14 = ndv;\n        result += ((L.sheen * _6831) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6840)) * _6840) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6820;\n        float param_18 = max(dot(v, _6820), 0.0f);\n        result += (_6831 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4789 = tdh / at;\n    float _4793 = bdh / ab;\n    float _4805 = ((_4789 * _4789) + (_4793 * _4793)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4805) * _4805);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4985 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5064 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5064) * _5064);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4985);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4985));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4195 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4198 = _4195.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4198 * _4198, exp2((-9.27999973297119140625f) * ndv)) * _4198) + _4195.y)) + _4195.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3506;\n    if (lv == 0)\n    {\n        _3506 = 0.0f;\n    }\n    else\n    {\n        _3506 = res + 2.0f;\n    }\n    float _3516;\n    if (lv == 0)\n    {\n        _3516 = 0.0f;\n    }\n    else\n    {\n        _3516 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3506, _3516)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3561;\n    if (res > 64.5f)\n    {\n        _3561 = 5.0f;\n    }\n    else\n    {\n        _3561 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3576 = clamp(rough, 0.0f, 1.0f) * (_3561 - 1.0f);\n    int _3583 = int(min(floor(_3576), _3561 - 2.0f));\n    float _3588 = _3576 - float(_3583);\n    float3 param = d;\n    float2 _3592 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3583;\n    float2 param_4 = _3592;\n    float3 _3602 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3588 < 0.00200000009499490261077880859375f)\n    {\n        return _3602;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3583 + 1;\n    float2 param_8 = _3592;\n    return lerp(_3602, fa_probe_level(param_5, param_6, param_7, param_8), _3588.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3672 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3679 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3686 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3692 = dot(bx.xyz, d);\n    float _3696 = dot(by.xyz, d);\n    float _3700 = dot(bz.xyz, d);\n    float _3706;\n    if (_3692 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3706 = (1.0f - _3672) / _3692;\n    }\n    else\n    {\n        float _3720;\n        if (_3692 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3720 = ((-1.0f) - _3672) / _3692;\n        }\n        else\n        {\n            _3720 = 1000000015047466219876688855040.0f;\n        }\n        _3706 = _3720;\n    }\n    float tx = _3706;\n    float _3737;\n    if (_3696 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3737 = (1.0f - _3679) / _3696;\n    }\n    else\n    {\n        float _3750;\n        if (_3696 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3750 = ((-1.0f) - _3679) / _3696;\n        }\n        else\n        {\n            _3750 = 1000000015047466219876688855040.0f;\n        }\n        _3737 = _3750;\n    }\n    float ty = _3737;\n    float _3766;\n    if (_3700 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3766 = (1.0f - _3686) / _3700;\n    }\n    else\n    {\n        float _3779;\n        if (_3700 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3779 = ((-1.0f) - _3686) / _3700;\n        }\n        else\n        {\n            _3779 = 1000000015047466219876688855040.0f;\n        }\n        _3766 = _3779;\n    }\n    float _3791 = tx;\n    float _3794 = (_3791 > 0.0f) ? _3791 : 1000000015047466219876688855040.0f;\n    tx = _3794;\n    float _3795 = ty;\n    float _3798 = (_3795 > 0.0f) ? _3795 : 1000000015047466219876688855040.0f;\n    ty = _3798;\n    float _3808 = min(_3794, min(_3798, (_3766 > 0.0f) ? _3766 : 1000000015047466219876688855040.0f));\n    if (_3808 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3824 = (fa_world_pos + (d * _3808)) - posw.xyz;\n    float3 _3829;\n    if (dot(_3824, _3824) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3829 = normalize(_3824);\n    }\n    else\n    {\n        _3829 = d;\n    }\n    return _3829;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3875 = (1.0f - _654_fa_rpa_tile.w) - _654_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3875 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_654_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _654_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3904 = rough * rough;\n            float _3935 = 0.60000002384185791015625f * _3904;\n            base = lerp(lerp(_654_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_654_fa_env_horizon.xyz, _654_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3904)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3935, 0.0500000007450580596923828125f + _3935, d.y).xxx), ((_654_fa_env_sky.xyz + _654_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3904 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3875;\n    }\n    if (_654_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _654_fa_rpa_tile;\n        float4 param_5 = _654_fa_rpa_pos;\n        float4 param_6 = _654_fa_rpa_bx;\n        float4 param_7 = _654_fa_rpa_by;\n        float4 param_8 = _654_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3994 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3994 * _654_fa_rpa_tile.w);\n    }\n    if (_654_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _654_fa_rpb_tile;\n        float4 param_12 = _654_fa_rpb_pos;\n        float4 param_13 = _654_fa_rpb_bx;\n        float4 param_14 = _654_fa_rpb_by;\n        float4 param_15 = _654_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4026 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4026 * _654_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4672;\n        if (L.aniso >= 0.0f)\n        {\n            _4672 = L.b;\n        }\n        else\n        {\n            _4672 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4672, v), _4672), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4705 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4705.x) + (L.f90.xxx * _4705.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4760 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4760.x) + _4760.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4237 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4237.x) + _4237.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_654_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_654_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5462 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5466 = fa_xm_origin(param_1);\n    float2 _5472 = (uv * _5462) - 0.5f.xx;\n    float2 _5475 = frac(_5472);\n    float2 _5478 = floor(_5472);\n    float2 param_2 = _5462;\n    float2 param_3 = _5466;\n    float2 param_4 = _5478;\n    float2 param_5 = _5462;\n    float2 param_6 = _5466;\n    float2 param_7 = _5478 + float2(1.0f, 0.0f);\n    float2 param_8 = _5462;\n    float2 param_9 = _5466;\n    float2 param_10 = _5478 + float2(0.0f, 1.0f);\n    float2 param_11 = _5462;\n    float2 param_12 = _5466;\n    float2 param_13 = _5478 + 1.0f.xx;\n    float3 _5520 = _5475.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5520), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5520), _5475.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5539 = max(_654_fa_tr_b.w - 1.0f, 0.0f);\n    float _5543 = clamp(lod, 0.0f, _5539);\n    int _5547 = int(floor(_5543));\n    int param = _5547;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5557 = float(_5547);\n    float _5558 = _5543 - _5557;\n    bool _5560 = _5558 > 0.001000000047497451305389404296875f;\n    bool _5567;\n    if (_5560)\n    {\n        _5567 = _5557 < _5539;\n    }\n    else\n    {\n        _5567 = _5560;\n    }\n    if (_5567)\n    {\n        int param_2 = _5547 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5558.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5593 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _5593.x) + (f90.xxx * _5593.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _5621 = max(s.thickness, 0.0f);\n    bool _5626 = _5621 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5626)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5621);\n    }\n    bool _5651 = _654_fa_tr_a.w > 1.5f;\n    bool _5658;\n    if (!_5651)\n    {\n        _5658 = _654_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5658 = _5651;\n    }\n    if (_5658)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_5626)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5621);\n    }\n    float4 _5693 = float4(world, 1.0f);\n    float _5698 = dot(_654_fa_ct_vpw, _5693);\n    float2 uv = 0.5f.xx;\n    if (_5698 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5716 = float2(dot(_654_fa_ct_vpx, _5693), dot(_654_fa_ct_vpy, _5693)) / _5698.xx;\n        float _5724;\n        if (_654_fa_ct_a.y > 0.5f)\n        {\n            _5724 = (_5716.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5724 = 0.5f - (_5716.y * 0.5f);\n        }\n        uv = float2((_5716.x * 0.5f) + 0.5f, _5724);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_654_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2321_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3257 = int(_2321_fa_shadow_cfg.x + 0.5f);\n    float _3267 = dot(world - _2321_fa_shadow_eye.xyz, _2321_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3272 = _3257 > 0;\n    bool _3281;\n    if (_3272)\n    {\n        int param = _3257 - 1;\n        _3281 = _3267 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3281 = _3272;\n    }\n    if (_3281)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3287 = _3257 > 1;\n        bool _3294;\n        if (_3287)\n        {\n            _3294 = _3267 > _2321_fa_shadow_split.x;\n        }\n        else\n        {\n            _3294 = _3287;\n        }\n        if (_3294)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3300 = _3257 > 2;\n        bool _3307;\n        if (_3300)\n        {\n            _3307 = _3267 > _2321_fa_shadow_split.y;\n        }\n        else\n        {\n            _3307 = _3300;\n        }\n        if (_3307)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3313 = _3257 > 3;\n        bool _3320;\n        if (_3313)\n        {\n            _3320 = _3267 > _2321_fa_shadow_split.z;\n        }\n        else\n        {\n            _3320 = _3313;\n        }\n        if (_3320)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _8606 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8606 = -_8606;\n    }\n    float3 _7896 = normalize(_654_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _8619 = { fa_world_pos, _8606, fa_world_tangent, fa_uv, fa_vertex_color, _7896, gl_FrontFacing };\n    SurfaceInput param_1 = _8619;\n    Surface _7904 = fa_standard_surface(param_1);\n    float3 _8637 = _7904.albedo;\n    float _8638 = _7904.alpha;\n    float3 _8639 = _7904.normal;\n    float _8640 = _7904.metallic;\n    float _8641 = _7904.roughness;\n    float _8642 = _7904.occlusion;\n    float3 _8643 = _7904.emission;\n    float _8644 = _7904.clearcoat;\n    float _8645 = _7904.clearcoat_roughness;\n    float3 _8646 = _7904.sheen_color;\n    float _8647 = _7904.sheen_roughness;\n    float _8648 = _7904.anisotropy;\n    float _8649 = _7904.anisotropy_rotation;\n    float _8650 = _7904.specular;\n    float _8651 = _7904.ior;\n    float3 _8652 = _7904.specular_color;\n    float _8653 = _7904.transmission;\n    float _8654 = _7904.thickness;\n    float3 _8655 = _7904.attenuation_color;\n    float _8656 = _7904.attenuation_distance;\n    SurfaceInput _8627 = { fa_world_pos, _8606, fa_world_tangent, fa_uv, fa_vertex_color, _7896, gl_FrontFacing };\n    SurfaceInput param_2 = _8627;\n    Surface param_3 = _7904;\n    surface(param_2, param_3);\n    _8637 = param_3.albedo;\n    _8638 = param_3.alpha;\n    _8639 = param_3.normal;\n    _8640 = param_3.metallic;\n    _8641 = param_3.roughness;\n    _8642 = param_3.occlusion;\n    _8643 = param_3.emission;\n    _8644 = param_3.clearcoat;\n    _8645 = param_3.clearcoat_roughness;\n    _8646 = param_3.sheen_color;\n    _8647 = param_3.sheen_roughness;\n    _8648 = param_3.anisotropy;\n    _8649 = param_3.anisotropy_rotation;\n    _8650 = param_3.specular;\n    _8651 = param_3.ior;\n    _8652 = param_3.specular_color;\n    _8653 = param_3.transmission;\n    _8654 = param_3.thickness;\n    _8655 = param_3.attenuation_color;\n    _8656 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _8606;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8637 = param_6;\n    _8639 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_654_fa_emissive.w > 0.5f)\n    {\n        result = _8637;\n    }\n    else\n    {\n        float3 _7944 = normalize(_8639);\n        float _7951 = clamp(_8640, 0.0f, 1.0f);\n        float _7955 = clamp(_8641, 0.0500000007450580596923828125f, 1.0f);\n        float _7959 = _7955 * _7955;\n        float _7963 = _7959 * _7959;\n        float _7968 = max(dot(_7944, _7896), 9.9999997473787516355514526367188e-05f);\n        float _7974 = 1.0f - _7951;\n        float _7975 = clamp(_8653, 0.0f, 1.0f) * _7974;\n        float3 _7984 = (_8637 * _7974) * (1.0f - _7975);\n        float3 _7991 = lerp(0.039999999105930328369140625f.xxx, _8637, _7951.xxx);\n        float3 f0 = _7991;\n        SurfaceInput _8635 = { fa_world_pos, _8606, fa_world_tangent, fa_uv, fa_vertex_color, _7896, gl_FrontFacing };\n        SurfaceInput param_8 = _8635;\n        Surface _8738 = { _8637, _8638, _8639, _8640, _8641, _8642, _8643, _8644, _8645, _8646, _8647, _8648, _8649, _8650, _8651, _8652, _8653, _8654, _8655, _8656 };\n        Surface param_9 = _8738;\n        float3 param_10 = _7944;\n        float3 param_11 = _7896;\n        float param_12 = _7951;\n        float param_13 = _7955;\n        float3 param_14 = _7991;\n        FaLayers _8007 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _7944;\n        float3 lit = (fa_indirect_diffuse(param_15) * _7984) * _8642;\n        if (_8007.on)\n        {\n            lit *= _8007.base_scale;\n        }\n        int _8029 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8029; ln++)\n        {\n            int param_16 = ln;\n            int _8042 = fa_cl_light(param_16);\n            int param_17 = _8042;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8042;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _8606;\n            LightSample _8058 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8066 = max(dot(_7944, _8058.direction), 0.0f);\n            float _8072 = _8058.attenuation * _8058.shadow;\n            float3 _8077 = normalize(_8058.direction + _7896);\n            float _8082 = max(dot(_7944, _8077), 0.0f);\n            float _8087 = max(dot(_7896, _8077), 0.0f);\n            bool _8094;\n            if (fa_light_is_area)\n            {\n                _8094 = !_8007.on;\n            }\n            else\n            {\n                _8094 = fa_light_is_area;\n            }\n            if (_8094)\n            {\n                int param_21 = _8042;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _7944;\n                float3 param_24 = _7896;\n                float3 param_25 = _7984;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _7955;\n                float param_29 = _7968;\n                float param_30 = _8072;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8007;\n                    int param_32 = _8042;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _7944;\n                    float3 param_35 = _7896;\n                    float3 param_36 = _8058.direction;\n                    float3 param_37 = _7984;\n                    float3 param_38 = f0;\n                    float param_39 = _7955;\n                    float param_40 = _7968;\n                    float param_41 = _8072;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8007.on)\n                    {\n                        FaLayers param_42 = _8007;\n                        float3 param_43 = _7984;\n                        float3 param_44 = f0;\n                        float3 param_45 = _7944;\n                        float3 param_46 = _7896;\n                        float3 param_47 = _8058.direction;\n                        float3 param_48 = _8077;\n                        float param_49 = _8066;\n                        float param_50 = _7968;\n                        float param_51 = _8082;\n                        float param_52 = _8087;\n                        float param_53 = _7959;\n                        float param_54 = _7963;\n                        int param_55 = _8042;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8072));\n                    }\n                    else\n                    {\n                        float _8200 = ((_8082 * _8082) * (_7963 - 1.0f)) + 1.0f;\n                        int param_56 = _8042;\n                        lit += (((_7984 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8087, 5.0f))) * (((_7963 / ((3.1415927410125732421875f * _8200) * _8200)) * (0.5f / max(lerp((2.0f * _8066) * _7968, _8066 + _7968, _7959), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8066))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8066 * _8072));\n                    }\n                }\n            }\n        }\n        if (_8007.on)\n        {\n            FaLayers param_57 = _8007;\n            float3 param_58 = _7944;\n            float3 param_59 = _7896;\n            float3 param_60 = f0;\n            float param_61 = _7955;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8642);\n        }\n        else\n        {\n            float3 param_62 = _7944;\n            float3 param_63 = _7896;\n            float3 param_64 = f0;\n            float param_65 = _7955;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8642);\n        }\n        if (_7975 > 0.0f)\n        {\n            float _8298;\n            if (_8007.on)\n            {\n                _8298 = _8007.f90;\n            }\n            else\n            {\n                _8298 = 1.0f;\n            }\n            float _8306;\n            if (_8007.on)\n            {\n                _8306 = _8007.base_scale;\n            }\n            else\n            {\n                _8306 = 1.0f;\n            }\n            Surface _8759 = { _8637, _8638, _8639, _8640, _8641, _8642, _8643, _8644, _8645, _8646, _8647, _8648, _8649, _8650, _8651, _8652, _8653, _8654, _8655, _8656 };\n            Surface param_66 = _8759;\n            float3 param_67 = _7944;\n            float3 param_68 = _7896;\n            float param_69 = _7955;\n            float3 param_70 = f0;\n            float param_71 = _8298;\n            float param_72 = _8306;\n            float param_73 = _7975;\n            float param_74 = fa_tr_blend;\n            float3 _8330 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _8330;\n        }\n        result = lit;\n    }\n    float3 _8337 = result;\n    float3 _8338 = _8337 + _8643;\n    result = _8338;\n    float3 param_75 = _8338;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _8347 = _654_fa_fog.w > 0.0f;\n    bool _8354;\n    if (!_8347)\n    {\n        _8354 = _654_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8354 = _8347;\n    }\n    if (_8354)\n    {\n        float3 _8363 = fa_world_pos - _654_fa_camera_pos.xyz;\n        float _8369 = dot(_8363, _654_fa_fog_c.xyz);\n        bool _8373 = _654_fa_fog_c.w > 0.5f;\n        float _8374;\n        if (_8373)\n        {\n            _8374 = _8369;\n        }\n        else\n        {\n            _8374 = length(_8363);\n        }\n        float _8386 = _8374 - _654_fa_fog_b.x;\n        if (_8386 > 0.0f)\n        {\n            float _8395 = _654_fa_fog.w * _8386;\n            float tau = _8395 * _8395;\n            if (_654_fa_fog_b.y > 0.0f)\n            {\n                float _8411;\n                if (_8373)\n                {\n                    _8411 = fa_world_pos.y - (_654_fa_fog_c.y * _8369);\n                }\n                else\n                {\n                    _8411 = _654_fa_camera_pos.y;\n                }\n                float _8432 = lerp(_8411, fa_world_pos.y, clamp(_654_fa_fog_b.x / _8374, 0.0f, 1.0f));\n                float _8436 = fa_world_pos.y - _8432;\n                float _8441 = _8432 - _654_fa_fog_b.z;\n                float _8446 = fa_world_pos.y - _654_fa_fog_b.z;\n                bool _8449 = _8441 <= 0.0f;\n                bool _8450 = !_8449;\n                bool _8456;\n                if (_8450)\n                {\n                    _8456 = _654_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8456 = _8449;\n                }\n                float _8457;\n                if (_8456)\n                {\n                    _8457 = _654_fa_fog_b.y;\n                }\n                else\n                {\n                    _8457 = _654_fa_fog_b.y * exp(-min(_654_fa_fog_b.w * _8441, 80.0f));\n                }\n                bool _8484;\n                if (_8450)\n                {\n                    _8484 = _654_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8484 = _8449;\n                }\n                float _8485;\n                if (_8484)\n                {\n                    _8485 = _654_fa_fog_b.y * _8441;\n                }\n                else\n                {\n                    _8485 = (_654_fa_fog_b.y * (1.0f - exp(-min(_654_fa_fog_b.w * _8441, 80.0f)))) / _654_fa_fog_b.w;\n                }\n                bool _8510 = _8446 <= 0.0f;\n                bool _8517;\n                if (!_8510)\n                {\n                    _8517 = _654_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8517 = _8510;\n                }\n                float _8518;\n                if (_8517)\n                {\n                    _8518 = _654_fa_fog_b.y * _8446;\n                }\n                else\n                {\n                    _8518 = (_654_fa_fog_b.y * (1.0f - exp(-min(_654_fa_fog_b.w * _8446, 80.0f)))) / _654_fa_fog_b.w;\n                }\n                float _8545;\n                if (abs(_8436) < 0.001000000047497451305389404296875f)\n                {\n                    _8545 = _8457;\n                }\n                else\n                {\n                    _8545 = (_8518 - _8485) / _8436;\n                }\n                tau += (_8386 * max(_8545, 0.0f));\n            }\n            result = lerp(result, _654_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _8581 = 1.0f - fa_tr_blend;\n        result /= _8581.xxx;\n        _8638 *= _8581;\n    }\n    fa_frag_color = float4(result, _8638);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_182",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_252",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_654",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2321",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _187_fa_view_proj : packoffset(c0);\n    row_major float4x4 _187_fa_light_vp : packoffset(c4);\n    float4 _187_fa_uv_scale : packoffset(c8);\n    float4 _187_fa_time : packoffset(c9);\n    float4 _187_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _231_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _364_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_231_fa_joint_rows[_222] * weights[i]);\n        r1 += (_231_fa_joint_rows[_222 + 1] * weights[i]);\n        r2 += (_231_fa_joint_rows[_222 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * _187_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _82;\n    if (!_67)\n    {\n        _82 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _187_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _364_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _4337[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _654_fa_camera_pos : packoffset(c0);\n    float4 _654_fa_ambient : packoffset(c1);\n    float4 _654_fa_base_color : packoffset(c2);\n    float4 _654_fa_emissive : packoffset(c3);\n    float4 _654_fa_model_emissive : packoffset(c4);\n    float4 _654_fa_pbr : packoffset(c5);\n    float4 _654_fa_maps : packoffset(c6);\n    float4 _654_fa_fog : packoffset(c7);\n    float4 _654_fa_fog_b : packoffset(c8);\n    float4 _654_fa_fog_c : packoffset(c9);\n    float4 _654_fa_counts : packoffset(c10);\n    float4 _654_fa_env_sky : packoffset(c11);\n    float4 _654_fa_env_horizon : packoffset(c12);\n    float4 _654_fa_time : packoffset(c13);\n    float4 _654_fa_cl_vpx : packoffset(c14);\n    float4 _654_fa_cl_vpy : packoffset(c15);\n    float4 _654_fa_cl_vpw : packoffset(c16);\n    float4 _654_fa_cl_fwd : packoffset(c17);\n    float4 _654_fa_cl_grid : packoffset(c18);\n    float4 _654_fa_cl_info : packoffset(c19);\n    float4 _654_fa_layers_a : packoffset(c20);\n    float4 _654_fa_layers_b : packoffset(c21);\n    float4 _654_fa_layers_c : packoffset(c22);\n    float4 _654_fa_layers_d : packoffset(c23);\n    float4 _654_fa_ct_a : packoffset(c24);\n    float4 _654_fa_ct_b : packoffset(c25);\n    float4 _654_fa_ct_vpx : packoffset(c26);\n    float4 _654_fa_ct_vpy : packoffset(c27);\n    float4 _654_fa_ct_vpw : packoffset(c28);\n    float4 _654_fa_ct_fwd : packoffset(c29);\n    float4 _654_fa_tr_a : packoffset(c30);\n    float4 _654_fa_tr_b : packoffset(c31);\n    float4 _654_fa_probe_sh[9] : packoffset(c32);\n    float4 _654_fa_atlas : packoffset(c41);\n    float4 _654_fa_rpa_tile : packoffset(c42);\n    float4 _654_fa_rpa_pos : packoffset(c43);\n    float4 _654_fa_rpa_bx : packoffset(c44);\n    float4 _654_fa_rpa_by : packoffset(c45);\n    float4 _654_fa_rpa_bz : packoffset(c46);\n    float4 _654_fa_rpb_tile : packoffset(c47);\n    float4 _654_fa_rpb_pos : packoffset(c48);\n    float4 _654_fa_rpb_bx : packoffset(c49);\n    float4 _654_fa_rpb_by : packoffset(c50);\n    float4 _654_fa_rpb_bz : packoffset(c51);\n    float4 _654_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2321_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2321_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2321_fa_shadow_info[4] : packoffset(c20);\n    float4 _2321_fa_shadow_split : packoffset(c24);\n    float4 _2321_fa_shadow_cfg : packoffset(c25);\n    float4 _2321_fa_shadow_bias : packoffset(c26);\n    float4 _2321_fa_shadow_eye : packoffset(c27);\n    float4 _2321_fa_shadow_fwd : packoffset(c28);\n    float4 _2321_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1592 = _654_fa_cl_info.x < 0.0f;\n    bool _1599;\n    if (!_1592)\n    {\n        _1599 = _654_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1599 = _1592;\n    }\n    bool _1607;\n    if (!_1599)\n    {\n        _1607 = _654_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1607 = _1599;\n    }\n    bool _1614;\n    if (!_1607)\n    {\n        _1614 = _654_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1614 = _1607;\n    }\n    bool _1621;\n    if (!_1614)\n    {\n        _1621 = _654_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1621 = _1614;\n    }\n    if (_1621)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1631 = float4(world_pos, 1.0f);\n    float _1637 = dot(_654_fa_cl_vpw, _1631);\n    if (!(_1637 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1659 = float2(dot(_654_fa_cl_vpx, _1631), dot(_654_fa_cl_vpy, _1631)) / _1637.xx;\n    int _1663 = int(_654_fa_cl_grid.x);\n    int _1667 = int(_654_fa_cl_grid.y);\n    int param = (int(_654_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_654_fa_cl_fwd.xyz, world_pos) + _654_fa_cl_fwd.w, _654_fa_cl_grid.w) / _654_fa_cl_grid.w) * _654_fa_cl_grid.z)), 0, int(_654_fa_cl_info.y) - 1) * _1667) + clamp(int(floor(((_1659.y * 0.5f) + 0.5f) * _654_fa_cl_grid.y)), 0, _1667 - 1)) * _1663)) + clamp(int(floor(((_1659.x * 0.5f) + 0.5f) * _654_fa_cl_grid.x)), 0, _1663 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1743 = fa_cluster_texel(param);\n    return int2(int(_1743.x), int(_1743.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_654_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _5798 = fa_cluster_lookup(param);\n    fa_cl_slot = _5798.x;\n    fa_cl_local = _5798.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _6946 = fa_linear_to_srgb(param);\n        c = _6946;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _6954 = fa_srgb_to_linear(param_1);\n            c = _6954;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _536;\n    if (i.front_facing)\n    {\n        _536 = i.world_normal;\n    }\n    else\n    {\n        _536 = -i.world_normal;\n    }\n    float3 _560 = normalize(i.world_tangent.xyz - (_536 * dot(_536, i.world_tangent.xyz)));\n    float3 _587 = normalize(((_560 * m.x) + ((cross(_536, _560) * i.world_tangent.w) * m.y)) + (_536 * m.z));\n    float3 _590;\n    if (i.front_facing)\n    {\n        _590 = _587;\n    }\n    else\n    {\n        _590 = -_587;\n    }\n    return _590;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _654_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _6985 = fa_tex_fix(param_2, param_3);\n    float4 _9183 = base_t;\n    _9183.x = _6985.x;\n    _9183.y = _6985.y;\n    _9183.z = _6985.z;\n    base_t = _9183;\n    float4 _6999 = (_9183 * _654_fa_base_color) * i.vertex_color;\n    float3 _8967 = i.world_normal;\n    if (_654_fa_maps.z > 0.5f)\n    {\n        float param_4 = _654_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7031 = fa_tex_fix(param_6, param_7);\n        float3 _7034 = (_7031 * 2.0f) - 1.0f.xxx;\n        float2 _7039 = _7034.xy * _654_fa_maps.x;\n        float3 _9191 = _7034;\n        _9191.x = _7039.x;\n        _9191.y = _7039.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9191;\n        _8967 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _654_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7067 = fa_tex_fix(param_12, param_13);\n    float4 _9194 = mrt;\n    _9194.x = _7067.x;\n    _9194.y = _7067.y;\n    _9194.z = _7067.z;\n    mrt = _9194;\n    float4 _7095 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _654_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7095.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7106 = fa_tex_fix(param_16, param_17);\n    float param_18 = _654_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7136 = fa_tex_fix(param_20, param_21);\n    float _8972 = _654_fa_layers_a.x;\n    float _8973 = _654_fa_layers_a.y;\n    float _8976 = _654_fa_layers_a.z;\n    float _8975 = _654_fa_layers_b.w;\n    float _8978 = _654_fa_layers_c.x;\n    if (_654_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_654_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _8972 *= _7106.y;\n            _8973 *= _7106.z;\n            _8975 *= _7095.w;\n        }\n        if (_654_fa_layers_c.z > 1.5f)\n        {\n            _8976 *= mrt.x;\n            _8978 *= mrt.w;\n        }\n    }\n    Surface _9005 = { _6999.xyz, _6999.w, _8967, clamp(_654_fa_pbr.x * _7067.z, 0.0f, 1.0f), clamp(_654_fa_pbr.y * _7067.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_654_fa_maps.y * (_7106.x - 1.0f)), _654_fa_emissive.xyz + (_654_fa_model_emissive.xyz * _7136), _8972, _8973, _654_fa_layers_b.xyz, _8975, _8976, _654_fa_layers_a.w, _8978, _654_fa_layers_c.y, _654_fa_layers_d.xyz, _654_fa_tr_a.x, _654_fa_tr_a.y, _654_fa_tr_b.xyz, _654_fa_tr_a.z };\n    return _9005;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1823 = rect.zw - rect.xy;\n    float2 _1827 = _1823 * atlas;\n    float2 _1831 = ddx * _1827;\n    float2 _1835 = ddy * _1827;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1823), clamp(0.5f * log2(max(max(dot(_1831, _1831), dot(_1835, _1835)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1868 = _654_fa_counts.y < 0.5f;\n    bool _1875;\n    if (!_1868)\n    {\n        _1875 = _654_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1875 = _1868;\n    }\n    if (_1875)\n    {\n        return;\n    }\n    float3 _1881 = ddx(world_pos);\n    float3 _1884 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1888 = fa_cluster_texel(param);\n    int _1892 = int(_1888.w);\n    if (_1892 < 1)\n    {\n        return;\n    }\n    int _1902 = int(_654_fa_counts.y + 0.5f);\n    int param_1 = _1902;\n    float4 _1906 = fa_light_texel(param_1);\n    float2 _1909 = _1906.yz;\n    int _1913 = int(_1906.w);\n    int param_2 = _1902 + 1;\n    float4 _1918 = fa_light_texel(param_2);\n    float _1919 = _1918.x;\n    int _1925 = int(_654_fa_counts.w + 0.5f) - 1;\n    int _1929 = int(_1888.z);\n    float3 _2194;\n    for (int k = 0; k < _1892; k++)\n    {\n        int _1942 = _1929 + k;\n        int param_3 = _1913 + (_1942 >> 2);\n        int _1959 = (_1902 + 2) + (int(fa_light_texel(param_3)[_1942 & 3]) * 7);\n        int param_4 = _1959 + 6;\n        float4 _1964 = fa_light_texel(param_4);\n        if (((int(_1964.w + 0.5f) >> _1925) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1959;\n        float4 _1979 = fa_light_texel(param_5);\n        int param_6 = _1959 + 1;\n        float4 _1984 = fa_light_texel(param_6);\n        int param_7 = _1959 + 2;\n        float4 _1989 = fa_light_texel(param_7);\n        float3 _1992 = _1979.xyz;\n        float _1997 = dot(_1992, world_pos) + _1979.w;\n        float3 _1999 = _1984.xyz;\n        float _2004 = dot(_1999, world_pos) + _1984.w;\n        float3 _2006 = _1989.xyz;\n        float _2011 = dot(_2006, world_pos) + _1989.w;\n        bool _2016 = abs(_1997) > 0.5f;\n        bool _2024;\n        if (!_2016)\n        {\n            _2024 = abs(_2004) > 0.5f;\n        }\n        else\n        {\n            _2024 = _2016;\n        }\n        bool _2032;\n        if (!_2024)\n        {\n            _2032 = abs(_2011) > 0.5f;\n        }\n        else\n        {\n            _2032 = _2024;\n        }\n        if (_2032)\n        {\n            continue;\n        }\n        float _2047 = clamp(dot(geo_normal, normalize(_2006)) * _1964.z, 0.0f, 1.0f);\n        if (_2047 <= 0.0f)\n        {\n            continue;\n        }\n        float _2067 = (clamp((0.5f - abs(_2011)) * 10.0f, 0.0f, 1.0f) * _2047) * _1964.x;\n        float2 _2075 = float2(_1997 + 0.5f, 0.5f - _2004);\n        float2 _2085 = float2(dot(_1992, _1881), dot(_1999, _1881));\n        float2 _2095 = float2(dot(_1992, _1884), dot(_1999, _1884));\n        int param_8 = _1959 + 5;\n        float4 _2100 = fa_light_texel(param_8);\n        int param_9 = _1959 + 3;\n        float4 _2105 = fa_light_texel(param_9);\n        int param_10 = _1959 + 4;\n        float4 _2110 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2100.xyz;\n        bool _2120 = _2105.z > _2105.x;\n        if (_2120)\n        {\n            float4 param_11 = _2105;\n            float2 param_12 = _2075;\n            float2 param_13 = _1909;\n            float2 param_14 = _2085;\n            float2 param_15 = _2095;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1919 > 0.5f) && (_1919 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2146 = fa_dc_to_linear(param_16);\n                float4 _9055 = tx;\n                _9055.x = _2146.x;\n                _9055.y = _2146.y;\n                _9055.z = _2146.z;\n                tx = _9055;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2067 * tex_a) * _2100.w, 0.0f, 1.0f).xxx);\n        if (_2110.z > _2110.x)\n        {\n            float4 param_17 = _2110;\n            float2 param_18 = _2075;\n            float2 param_19 = _1909;\n            float2 param_20 = _2085;\n            float2 param_21 = _2095;\n            float4 _2190 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1919 > 1.5f)\n            {\n                float3 param_22 = _2190.xyz;\n                float3 _2200 = fa_dc_to_srgb(param_22);\n                _2194 = _2200;\n            }\n            else\n            {\n                _2194 = _2190.xyz;\n            }\n            float3 _2209 = (_2194 * 2.0f) - 1.0f.xxx;\n            float2 _2214 = _2209.xy * _1964.y;\n            float3 _2236 = (normalize(_1992) * _2214.x) + (normalize(_1999) * _2214.y);\n            float3 _2239 = normalize(normal);\n            normal = normalize(lerp(_2239, normalize((_2239 * max(_2209.z, 0.0500000007450580596923828125f)) + (_2236 - (_2239 * dot(_2239, _2236)))), clamp(_2067 * (_2120 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4263 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4270 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4273 = int(_4263);\n    int _4276 = int(_4270);\n    float _4286 = _4270 - float(_4276);\n    int _4341 = (_4273 * 9) + _4276;\n    int _4361 = ((_4273 + 1) * 9) + _4276;\n    return lerp(lerp(_4337[_4341], _4337[_4341 + 1], _4286), lerp(_4337[_4361], _4337[_4361 + 1], _4286), _4263 - float(_4273));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _8890 = false;\n    float _8891 = 1.0f;\n    float _8892 = 1.0f;\n    float _8893 = 1.0f;\n    float _8894 = 0.0f;\n    float _8895 = 0.0f;\n    float _8896 = 0.0f;\n    float _8897 = 0.0f;\n    float _8899 = 1.0f;\n    bool _8900 = false;\n    float3 _8901 = 0.0f.xxx;\n    float _8902 = 1.0f;\n    float _8903 = 1.0f;\n    float _8904 = 1.0f;\n    float _8905 = 0.0f;\n    float _8906 = 0.0f;\n    float3 _8907 = float3(1.0f, 0.0f, 0.0f);\n    float3 _8908 = float3(0.0f, 0.0f, 1.0f);\n    float _8909 = 1.0f;\n    float _8910 = 1.0f;\n    float _4412 = clamp(s.specular, 0.0f, 1.0f);\n    float _4416 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4421 = (_4412 != 1.0f) || (_4416 != 1.5f);\n    bool _4430;\n    if (!_4421)\n    {\n        _4430 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4430 = _4421;\n    }\n    if (_4430)\n    {\n        float _4438 = (_4416 - 1.0f) / (_4416 + 1.0f);\n        f0 = lerp(min((_4438 * _4438).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4412, s.albedo, metallic.xxx);\n        _8891 = lerp(_4412, 1.0f, metallic);\n        _8890 = true;\n    }\n    float _4465 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4465 > 0.0f)\n    {\n        float _4473 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _8894 = _4465;\n        _8895 = _4473;\n        float _4480 = _4473 * _4473;\n        _8896 = _4480;\n        _8897 = _4480 * _4480;\n        float _4492 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _8899 = _4492;\n        _8892 = 1.0f - (_4465 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4492, 0.0f, 1.0f), 5.0f))));\n        _8890 = true;\n    }\n    float3 _4511 = max(s.sheen_color, 0.0f.xxx);\n    float _4520 = max(_4511.x, max(_4511.y, _4511.z));\n    if (_4520 > 0.0f)\n    {\n        float _4528 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _8900 = true;\n        _8901 = _4511;\n        _8902 = _4528;\n        _8903 = _4528 * _4528;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4528;\n        float _4545 = fa_sheen_albedo(param, param_1);\n        _8905 = _4545;\n        _8904 = 1.0f - min(_4520 * _4545, 1.0f);\n        _8890 = true;\n    }\n    _8893 = _8892 * _8904;\n    float _4564 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4564 != 0.0f)\n    {\n        float3 _4579 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4579;\n        if (dot(_4579, _4579) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4591 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4591.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4591.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4591.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4595 = t;\n        float3 _4596 = normalize(_4595);\n        t = _4596;\n        float3 _4621 = normalize((_4596 * cos(s.anisotropy_rotation)) + ((cross(n, _4596) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _8907 = _4621;\n        _8908 = cross(n, _4621);\n        float _4631 = roughness * roughness;\n        float _4637 = lerp(_4631, 1.0f, _4564 * _4564);\n        bool _4639 = _4564 > 0.0f;\n        _8909 = _4639 ? _4637 : _4631;\n        _8910 = _4639 ? _4631 : _4637;\n        _8906 = _4564;\n        _8890 = true;\n    }\n    FaLayers _8932 = { _8890, _8891, _8892, _8893, _8894, _8895, _8896, _8897, i.world_normal, _8899, _8900, _8901, _8902, _8903, _8904, _8905, _8906, _8907, _8908, _8909, _8910 };\n    return _8932;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3434 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3434;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3493_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3493_dummy_parameter)));\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3454 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3457 = _3454.x;\n    float _3459 = _3454.z;\n    float2 e = float2(_3457, _3459);\n    if (_3454.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3459)) * ((_3457 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3457)) * ((_3459 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7246 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7251 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7256 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7261 = fa_light_texel(param_3);\n    bool _7264 = _7261.z < 0.5f;\n    bool _7272;\n    if (!_7264)\n    {\n        _7272 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7272 = _7264;\n    }\n    if (_7272)\n    {\n        return 0.0f.xxx;\n    }\n    float _7279 = max(_7246.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7282 = _7251.xyz;\n    float3 _7286 = _7246.xyz;\n    float3 _7290 = (fa_world_pos - _7286) / _7279.xxx;\n    float3 _7299 = min(_7290 + 0.5f.xxx, (_7282 - 0.5f.xxx) - _7290);\n    float _7308 = min(_7299.x, min(_7299.y, _7299.z));\n    if (!(_7308 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7323 = _7282 - 1.0f.xxx;\n    float3 _7324 = clamp(_7290, 0.0f.xxx, _7323);\n    float3 _7332 = min(floor(_7324), max(_7282 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7336 = _7324 - _7332;\n    float3 _7347 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7279));\n    int _7352 = int(_7256.y + 0.5f);\n    float3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = 0.0f.xxx;\n    }\n    float wsum = 0.0f;\n    int _7370 = int(_7261.w);\n    int _7371 = 8 + _7370;\n    int _7376 = 9 + _7370;\n    float _7403;\n    float _7416;\n    float _7430;\n    for (int k_1 = 0; k_1 < _7371; k_1++)\n    {\n        float _7389 = float(k_1 & 1);\n        float _7393 = float((k_1 >> 1) & 1);\n        float _7397 = float((k_1 >> 2) & 1);\n        if (_7389 > 0.5f)\n        {\n            _7403 = _7336.x;\n        }\n        else\n        {\n            _7403 = 1.0f - _7336.x;\n        }\n        if (_7393 > 0.5f)\n        {\n            _7416 = _7336.y;\n        }\n        else\n        {\n            _7416 = 1.0f - _7336.y;\n        }\n        if (_7397 > 0.5f)\n        {\n            _7430 = _7336.z;\n        }\n        else\n        {\n            _7430 = 1.0f - _7336.z;\n        }\n        float _7440 = (_7403 * _7416) * _7430;\n        if (!(_7440 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7453 = min(_7332 + float3(_7389, _7393, _7397), _7323);\n        int _7473 = int(((_7256.x + _7453.x) + (_7251.x * (_7453.y + (_7251.y * _7453.z)))) + 0.5f);\n        float2 _7488 = float2(float(_7473 % _7352) * 10.0f, 1024.0f + (float(_7473 / _7352) * 11.0f));\n        float2 param_4 = _7488 + float2(9.5f, 10.5f);\n        float4 _7496 = fa_gi_fetch(param_4);\n        bool _7499 = _7496.y < 0.5f;\n        bool _7508;\n        if (!_7499)\n        {\n            _7508 = _7496.x > _7261.y;\n        }\n        else\n        {\n            _7508 = _7499;\n        }\n        if (_7508)\n        {\n            continue;\n        }\n        float3 _7520 = _7347 - (_7286 + (_7453 * _7279));\n        float _7523 = length(_7520);\n        float3 _7529 = _7520 / max(_7523, 9.9999997473787516355514526367188e-05f).xxx;\n        float _7539 = max(9.9999997473787516355514526367188e-05f, (dot(-_7529, n) + 1.0f) * 0.5f);\n        float w = _7440 * (_7539 * _7539);\n        float3 param_5 = _7529;\n        float2 param_6 = (_7488 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _7558 = fa_gi_fetch(param_6);\n        float _7565 = _7523 / max(_7256.z, 9.9999997473787516355514526367188e-05f);\n        float _7568 = _7558.x;\n        if (_7565 > _7568)\n        {\n            float _7581 = max(_7558.y - (_7568 * _7568), 0.0f);\n            float _7586 = _7565 - _7568;\n            float _7595 = _7581 / max(_7581 + (_7586 * _7586), 9.9999999600419720025001879548654e-13f);\n            w *= ((_7595 * _7595) * _7595);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        for (int c = 0; c < _7376; c++)\n        {\n            float2 param_7 = _7488 + float2(float(c) + 0.5f, 10.5f);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= wsum.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7308 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _7676;\n    if (_654_fa_gi.z > 0.5f)\n    {\n        _7676 = _7261.x;\n    }\n    else\n    {\n        _7676 = 1.0f;\n    }\n    float3 param_8[9] = sh;\n    float3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_7256.w * _7676);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _7700 = normalize(_654_fa_camera_pos.xyz - fa_world_pos);\n    int _7705 = int(_654_fa_gi.x + 0.5f);\n    int _7710 = int(_654_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _7710) && (k < 8); k++)\n    {\n        int param = _7705 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _7700;\n        float3 _7735 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7740 = param_3 * left;\n        acc += (_7735 * _7740);\n        left -= _7740;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_654_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4044 = (1.0f - _654_fa_rpa_tile.w) - _654_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4049 = _654_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4044 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4049)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _654_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4044;\n            }\n        }\n        else\n        {\n            amb = _654_fa_ambient.xyz * _4044;\n        }\n    }\n    bool _4100 = _654_fa_rpa_tile.w > 0.0f;\n    if (_4100)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _654_fa_rpa_tile.xy;\n            float param_4 = _654_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _654_fa_rpa_tile.w);\n        }\n    }\n    bool _4131 = _654_fa_rpb_tile.w > 0.0f;\n    if (_4131)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _654_fa_rpb_tile.xy;\n            float param_7 = _654_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _654_fa_rpb_tile.w);\n        }\n    }\n    if ((_4049 || _4100) || _4131)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    if (_654_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _7769 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375f)\n        {\n            float3 _7777;\n            if (param_1 > 0.0f)\n            {\n                float3 param_2 = n;\n                _7777 = _7769 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _7777 = _7769;\n            }\n            return _7777;\n        }\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_654_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _654_fa_probe_sh[k].xyz;\n        }\n        float3 param[9] = c;\n        float3 param_1 = n;\n        float3 _7839 = fa_sh_eval(param, param_1);\n        if (_654_fa_probe_sh[0].w >= 1.0f)\n        {\n            return _7839;\n        }\n        float3 param_2 = n;\n        return lerp(fa_realtime_or_ambient(param_2), _7839, clamp(_654_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_654_fa_cl_info.x) + int(_654_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_654_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5768;\n    if (fa_lm.z > 0.5f)\n    {\n        _5768 = 0.0f;\n    }\n    else\n    {\n        _5768 = 1.0f - clamp(_654_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _5779 = _5768 < 1.0f;\n    bool _5785;\n    if (_5779)\n    {\n        int param = li;\n        _5785 = fa_light_baked(param);\n    }\n    else\n    {\n        _5785 = _5779;\n    }\n    return _5785 ? _5768 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _722_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _722_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _841 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _854 = (c - (ru * hx)) - p;\n        float3 _860 = ru * (2.0f * hx);\n        float _866 = max(dot(_860, _860), 9.9999999392252902907785028219223e-09f);\n        float _870 = dot(_854, _860);\n        float t = clamp((-_870) / _866, 0.0f, 1.0f);\n        if (_841)\n        {\n            float _885 = dot(r, _860);\n            float _891 = _866 - (_885 * _885);\n            if (abs(_891) > (9.9999997473787516355514526367188e-06f * _866))\n            {\n                t = clamp(((dot(r, _854) * _885) - _870) / _891, 0.0f, 1.0f);\n            }\n        }\n        return (p + _854) + (_860 * t);\n    }\n    float3 q = p;\n    float _923 = dot(r, axis);\n    bool _931;\n    if (_841)\n    {\n        _931 = abs(_923) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _931 = _841;\n    }\n    if (_931)\n    {\n        float _941 = dot(c - p, axis) / _923;\n        if (_941 > 0.0f)\n        {\n            q = p + (r * _941);\n        }\n    }\n    float3 _954 = q - c;\n    float2 xy = float2(dot(_954, ru), dot(_954, uu));\n    if (shape > 0.5f)\n    {\n        float _969 = length(xy);\n        if (_969 > hx)\n        {\n            xy *= (hx / _969);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _602 = abs(d);\n    float _604 = _602.x;\n    float _606 = _602.y;\n    bool _607 = _604 >= _606;\n    bool _615;\n    if (_607)\n    {\n        _615 = _604 >= _602.z;\n    }\n    else\n    {\n        _615 = _607;\n    }\n    int _616;\n    if (_615)\n    {\n        _616 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _631;\n        if (_606 >= _602.z)\n        {\n            _631 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _631 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _616 = _631;\n    }\n    return _616;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _761 = dot(d, right);\n    float _765 = dot(d, up);\n    float _776;\n    if (((_761 * _761) + (_765 * _765)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _776 = atan2(_765, _761) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _776 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_776 - floor(_776)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1007 = fa_light_base(param);\n    bool _1011 = _654_fa_ambient.w > 4.5f;\n    int param_1 = _1007;\n    float4 _1015 = fa_light_texel(param_1);\n    int param_2 = _1007 + 1;\n    float4 _1020 = fa_light_texel(param_2);\n    float _1023 = _1020.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1035 = _1011 && (_1023 > 2.5f);\n    fa_light_is_area = _1035;\n    bool _1037 = _1023 < 0.5f;\n    float3 l;\n    if (_1037)\n    {\n        l = normalize(_1015.xyz);\n        if (_1011)\n        {\n            int param_3 = _1007 + 6;\n            float4 _1051 = fa_light_texel(param_3);\n            if (_1051.z > 0.5f)\n            {\n                int param_4 = _1007 + 4;\n                float4 _1061 = fa_light_texel(param_4);\n                int param_5 = _1007 + 5;\n                float4 _1066 = fa_light_texel(param_5);\n                float2 param_6 = _1051.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1061.xyz) * _1061.w, (-dot(world_pos, _1066.xyz)) * _1066.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1096 = _1015.xyz;\n        float3 _1098 = _1096 - world_pos;\n        float3 to_light = _1098;\n        float _1101 = length(_1098);\n        float reach = _1101;\n        bool front = true;\n        if (_1035)\n        {\n            int param_8 = _1007 + 7;\n            reach = max(_1101 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1007 + 4;\n            float4 _1125 = fa_light_texel(param_9);\n            int param_10 = _1007 + 5;\n            float4 _1130 = fa_light_texel(param_10);\n            int param_11 = _1007 + 6;\n            float4 _1135 = fa_light_texel(param_11);\n            float _1136 = _1135.w;\n            int param_12 = _1007 + 2;\n            float3 _1143 = normalize(fa_light_texel(param_12).xyz);\n            bool _1145 = _1136 > 1.5f;\n            bool _1153;\n            if (!_1145)\n            {\n                _1153 = dot(_1143, to_light) < 0.0f;\n            }\n            else\n            {\n                _1153 = _1145;\n            }\n            front = _1153;\n            float3 r = 0.0f.xxx;\n            float3 _1162 = _654_fa_camera_pos.xyz - world_pos;\n            bool _1166 = dot(n, n) > 0.5f;\n            bool _1174;\n            if (_1166)\n            {\n                _1174 = dot(_1162, _1162) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1174 = _1166;\n            }\n            if (_1174)\n            {\n                r = reflect(-normalize(_1162), normalize(n));\n            }\n            float3 param_13 = _1096;\n            float3 param_14 = _1143;\n            float3 param_15 = _1125.xyz;\n            float3 param_16 = _1130.xyz;\n            float param_17 = _1125.w;\n            float param_18 = _1130.w;\n            float param_19 = _1136;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1210 = length(to_light);\n        dist = _1210;\n        l = to_light / max(_1210, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1224 = reach / max(_1015.w, 0.001000000047497451305389404296875f);\n        float _1230 = clamp(1.0f - (_1224 * _1224), 0.0f, 1.0f);\n        float _1232;\n        if (front)\n        {\n            _1232 = _1230 * _1230;\n        }\n        else\n        {\n            _1232 = 0.0f;\n        }\n        atten = _1232;\n        bool _1243 = _1023 < 2.5f;\n        if ((_1023 > 1.5f) && _1243)\n        {\n            int param_22 = _1007 + 2;\n            float4 _1251 = fa_light_texel(param_22);\n            float _1261 = _1251.w;\n            int param_23 = _1007 + 3;\n            float4 _1266 = fa_light_texel(param_23);\n            float _1267 = _1266.x;\n            float cos_inner = _1267;\n            if (_1267 > 1.5f)\n            {\n                cos_inner = lerp(_1261, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1261, cos_inner, dot(-l, normalize(_1251.xyz)));\n        }\n        if (_1011 && (_1023 < 1.5f))\n        {\n            int param_24 = _1007 + 6;\n            float4 _1291 = fa_light_texel(param_24);\n            if (_1291.z > 0.5f)\n            {\n                float3 _1299 = -to_light;\n                int param_25 = _1007 + 4;\n                int param_26 = _1007 + 5;\n                float3 _1313 = fa_light_texel(param_25).xyz;\n                float3 _1317 = fa_light_texel(param_26).xyz;\n                float3 _1326 = float3(dot(_1299, _1313), dot(_1299, _1317), dot(_1299, cross(_1313, _1317)));\n                float3 param_27 = _1326;\n                int _1330 = fa_cube_face(param_27);\n                int param_28 = _1330;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1357 = float2(dot(_1326, cross(param_29, param_30)), dot(_1326, param_30)) / max(dot(_1326, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1361 = _1330 / 3;\n                float2 param_31 = _1291.xy + (float2(float(_1330 - (_1361 * 3)), float(_1361)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1357.x), 0.5f - (0.5f * _1357.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1007 + 7;\n            float4 _1391 = fa_light_texel(param_33);\n            if (_1391.z > 0.5f)\n            {\n                int param_34 = _1007 + 2;\n                int param_35 = _1007 + 4;\n                int param_36 = _1007 + 5;\n                float2 param_37 = _1391.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1011 && _1243)\n            {\n                int param_42 = _1007 + 6;\n                float4 _1438 = fa_light_texel(param_42);\n                int param_43 = _1007 + 7;\n                float4 _1443 = fa_light_texel(param_43);\n                bool _1446 = _1438.z > 0.5f;\n                bool _1453;\n                if (!_1446)\n                {\n                    _1453 = _1443.z > 0.5f;\n                }\n                else\n                {\n                    _1453 = _1446;\n                }\n                if (_1453)\n                {\n                    int param_44 = _1007 + 2;\n                    float4 _1460 = fa_light_texel(param_44);\n                    float3 _1464 = normalize(_1460.xyz);\n                    int param_45 = _1007 + 4;\n                    float4 _1469 = fa_light_texel(param_45);\n                    int param_46 = _1007 + 5;\n                    float4 _1474 = fa_light_texel(param_46);\n                    if (_1446)\n                    {\n                        float3 _1482 = -to_light;\n                        float _1489 = _1460.w;\n                        float _1505 = 0.5f / max(dot(_1482, _1464) * (sqrt(max(1.0f - (_1489 * _1489), 0.0f)) / max(_1489, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1438.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1482, _1469.xyz) * _1505), 0.5f - (dot(_1482, _1474.xyz) * _1505));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1443.z > 0.5f)\n                    {\n                        float2 param_49 = _1443.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1464;\n                        float3 param_52 = _1469.xyz;\n                        float3 param_53 = _1474.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _8878 = _1020.xyz * atten;\n    if (_1011)\n    {\n        _8878 *= fa_light_tint;\n    }\n    int _1574;\n    if (_1037)\n    {\n        _1574 = 0;\n    }\n    else\n    {\n        _1574 = ((_1023 > 1.5f) && (_1023 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _8889 = { l, _8878, atten, 1.0f, dist, _1574 };\n    return _8889;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2311;\n    if (i == 0)\n    {\n        _2311 = _2321_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2327;\n        if (i == 1)\n        {\n            _2327 = _2321_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2335;\n            if (i == 2)\n            {\n                _2335 = _2321_fa_shadow_split.z;\n            }\n            else\n            {\n                _2335 = _2321_fa_shadow_split.w;\n            }\n            _2327 = _2335;\n        }\n        _2311 = _2327;\n    }\n    return _2311;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2368 = fa_shadow_depth(param, param_1);\n    float _2372;\n    if (conv.x < 0.5f)\n    {\n        _2372 = _2368;\n    }\n    else\n    {\n        _2372 = (conv.y * conv.z) / (conv.z - (_2368 * (conv.z - conv.y)));\n    }\n    return _2372;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2299 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2299), sin(_2299)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2418 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2427;\n        if (k < 0.0f)\n        {\n            _2427 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2427 = k;\n        }\n        float _2447 = clamp((_2427 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2418;\n            float2 _2466 = fa_shadow_vogel(param_3, param_4, param_5) * _2447;\n            float2 param_6 = uv + (_2466 * _2321_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2478 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2478 < (zr - (length(_2466) * plane)))\n            {\n                sum += _2478;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0f)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0f) * unit) * _2514) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2536 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2536; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2536;\n        float param_11 = _2418;\n        float2 _2555 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2555 * _2321_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2555) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2536);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2597 = max(_2321_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2602 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2608 = sqrt(1.0f - (_2602 * _2602));\n    float _2615 = min(_2608 / max(_2602, 0.20000000298023223876953125f), 4.0f);\n    float _2620;\n    if (_2321_fa_shadow_bias.y > 0.0f)\n    {\n        _2620 = _2321_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2620 = 1.5f * _2321_fa_shadow_info[ci].x;\n    }\n    float4 _2645 = mul(float4(world + (n * (_2620 * _2608)), 1.0f), _2321_fa_shadow_mat[ci]);\n    float _2652 = _2645.x;\n    bool _2655 = _2652 < _2321_fa_shadow_rect[ci].x;\n    bool _2664;\n    if (!_2655)\n    {\n        _2664 = _2652 > _2321_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2664 = _2655;\n    }\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2645.y < _2321_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2645.y > _2321_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2689;\n    if (!_2682)\n    {\n        _2689 = _2645.z > 1.0f;\n    }\n    else\n    {\n        _2689 = _2682;\n    }\n    if (_2689)\n    {\n        return -1.0f;\n    }\n    float _2697;\n    if (_2321_fa_shadow_bias.x > 0.0f)\n    {\n        _2697 = _2321_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2697 = 1.5f * _2321_fa_shadow_info[ci].x;\n    }\n    float2 param = _2645.xy;\n    float4 param_1 = _2321_fa_shadow_rect[ci];\n    float param_2 = _2645.z - ((_2697 * (1.0f + (0.5f * _2615))) / _2597);\n    float param_3 = _2321_fa_shadow_info[ci].x;\n    float param_4 = _2597;\n    float param_5 = _2597 * 0.25f;\n    float param_6 = ((_2321_fa_shadow_info[ci].x * min(_2615, 3.0f)) * 0.5f) / _2597;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2321_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2321_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_654_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3075 = int(_2321_fa_shadow_cfg.x + 0.5f);\n    if (_3075 < 1)\n    {\n        return 1.0f;\n    }\n    float _3090 = dot(world - _2321_fa_shadow_eye.xyz, _2321_fa_shadow_fwd.xyz);\n    int param = _3075 - 1;\n    if (_3090 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3102 = _3075 > 1;\n    bool _3109;\n    if (_3102)\n    {\n        _3109 = _3090 > _2321_fa_shadow_split.x;\n    }\n    else\n    {\n        _3109 = _3102;\n    }\n    if (_3109)\n    {\n        ci = 1;\n    }\n    bool _3113 = _3075 > 2;\n    bool _3120;\n    if (_3113)\n    {\n        _3120 = _3090 > _2321_fa_shadow_split.y;\n    }\n    else\n    {\n        _3120 = _3113;\n    }\n    if (_3120)\n    {\n        ci = 2;\n    }\n    bool _3124 = _3075 > 3;\n    bool _3131;\n    if (_3124)\n    {\n        _3131 = _3090 > _2321_fa_shadow_split.z;\n    }\n    else\n    {\n        _3131 = _3124;\n    }\n    if (_3131)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3075)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3157 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3157;\n        if (_3157 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2321_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3182;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3182 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3182 = _2321_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3201 = _2321_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3182, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3212 = clamp((_3090 - (fa_shadow_split_at(param_7) - _3201)) / _3201, 0.0f, 1.0f);\n        if (_3212 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _3075)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3233 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3233;\n                if (_3233 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3212);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2755 = _654_fa_pbr.z < 0.5f;\n    bool _2762;\n    if (!_2755)\n    {\n        _2762 = _2321_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2762 = _2755;\n    }\n    if (_2762)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2321_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2775 = fa_light_texel(param);\n    float _2776 = _2775.x;\n    if (_2776 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2785 = int(_2776 + 0.5f);\n    int param_1 = _2785;\n    float4 _2789 = fa_light_texel(param_1);\n    int param_2 = _2785 + 1;\n    float4 _2794 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2797 = _2789.y;\n    if (_2797 > 0.0f)\n    {\n        float _2814 = 1.0f - smoothstep(0.75f * _2797, _2797, length(world - _2321_fa_shadow_eye.xyz));\n        fade = _2814;\n        if (_2814 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2789.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2838 = (_2785 + 2) + (face * 6);\n    int param_4 = _2838;\n    int param_5 = _2838 + 1;\n    int param_6 = _2838 + 3;\n    float4 _2852 = fa_light_texel(param_6);\n    int param_7 = _2838 + 4;\n    float4 _2857 = fa_light_texel(param_7);\n    int param_8 = _2838 + 5;\n    float4 _2862 = fa_light_texel(param_8);\n    float _2874 = _2862.x * max(dot(_2852, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2879 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2902 = clamp(dot(n, _2852.xyz), -1.0f, 1.0f);\n    float _2921 = min(sqrt(1.0f - (_2902 * _2902)) / max(abs(dot(n, world - lpos)) / max(dot(_2852, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2924 = _2794.y;\n    float _2926;\n    if (_2924 > 0.0f)\n    {\n        _2926 = _2924;\n    }\n    else\n    {\n        _2926 = 1.5f * _2874;\n    }\n    float4 _2946 = float4(world + (n * (_2926 * sqrt(1.0f - (_2879 * _2879)))), 1.0f);\n    float _2950 = dot(_2852, _2946);\n    float _2953 = _2862.y;\n    if (_2950 < _2953)\n    {\n        return 1.0f;\n    }\n    float2 _2968 = float2(dot(fa_light_texel(param_4), _2946), dot(fa_light_texel(param_5), _2946)) / _2950.xx;\n    float _2970 = _2968.x;\n    bool _2973 = _2970 < _2857.x;\n    bool _2982;\n    if (!_2973)\n    {\n        _2982 = _2970 > _2857.z;\n    }\n    else\n    {\n        _2982 = _2973;\n    }\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2968.y < _2857.y;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2968.y > _2857.w;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    if (_3000)\n    {\n        return 1.0f;\n    }\n    float _3006 = _2794.x;\n    float _3008;\n    if (_3006 > 0.0f)\n    {\n        _3008 = _3006;\n    }\n    else\n    {\n        _3008 = 1.5f * _2874;\n    }\n    float2 param_9 = _2968;\n    float4 param_10 = _2857;\n    float param_11 = _2950 - (_3008 * (1.0f + (0.5f * _2921)));\n    float param_12 = _2874;\n    float param_13 = 1.0f;\n    float param_14 = _2862.z * 0.25f;\n    float param_15 = (_2874 * min(_2921, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2953, _2862.z);\n    int param_17 = int(_2789.z + 0.5f);\n    float param_18 = _2789.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5149 = _654_fa_ct_a.x < 0.5f;\n    bool _5156;\n    if (!_5149)\n    {\n        _5156 = _2321_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5156 = _5149;\n    }\n    if (_5156)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2321_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5169 = fa_light_texel(param);\n    float _5170 = _5169.y;\n    float len = _5170;\n    if (_5170 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5182 = length(world - _654_fa_camera_pos.xyz);\n    float _5192 = 1.0f - smoothstep(0.5f * _654_fa_ct_b.x, _654_fa_ct_b.x, _5182);\n    if (_5192 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5198 = len;\n    float _5201 = min(_5198, 0.89999997615814208984375f * dist);\n    len = _5201;\n    float _5206 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5182);\n    float _5211 = _5206 + (0.5f * _5201);\n    float3 _5217 = world + (gn * _5206);\n    float _5219 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5283;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5234 = (float(k) + _5219) * 0.083333335816860198974609375f;\n        float3 _5242 = _5217 + (l * (_5234 * len));\n        float4 _5248 = float4(_5242, 1.0f);\n        float _5254 = dot(_654_fa_ct_vpw, _5248);\n        if (_5254 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5274 = float2(dot(_654_fa_ct_vpx, _5248), dot(_654_fa_ct_vpy, _5248)) / _5254.xx;\n        float _5278 = _5274.x * 0.5f;\n        float _5279 = _5278 + 0.5f;\n        if (_654_fa_ct_a.y > 0.5f)\n        {\n            _5283 = (_5274.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5283 = 0.5f - (_5274.y * 0.5f);\n        }\n        bool _5299 = _5279 < 0.0f;\n        bool _5306;\n        if (!_5299)\n        {\n            _5306 = _5279 >= 1.0f;\n        }\n        else\n        {\n            _5306 = _5299;\n        }\n        bool _5313;\n        if (!_5306)\n        {\n            _5313 = _5283 < 0.0f;\n        }\n        else\n        {\n            _5313 = _5306;\n        }\n        bool _5320;\n        if (!_5313)\n        {\n            _5320 = _5283 >= 1.0f;\n        }\n        else\n        {\n            _5320 = _5313;\n        }\n        if (_5320)\n        {\n            break;\n        }\n        float4 _5339 = fa_screen_tex.Load(int3(int2(float2(_5279, _5283) * _654_fa_ct_a.zw), 0));\n        if (_5339.w < 0.5f)\n        {\n            continue;\n        }\n        float _5358 = (dot(_654_fa_ct_fwd.xyz, _5242) + _654_fa_ct_fwd.w) - _5339.x;\n        if ((_5358 > _5206) && (_5358 < _5211))\n        {\n            occ = max(occ, (1.0f - (_5234 * _5234)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5279, 0.5f - _5278), min(_5283, 1.0f - _5283))));\n        }\n    }\n    return 1.0f - (occ * _5192);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _5824 = fa_baked_keep(param);\n    if (_5824 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _8945 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _8945;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _5850 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _8947 = _5850.color;\n    float _8948 = _5850.attenuation;\n    float _8949 = _5850.shadow;\n    bool _5853 = _5850.type == 0;\n    if (_5853 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _5850.direction;\n        float _5864 = fa_shadow_factor(param_5, param_6);\n        _8949 = _5864;\n        _8947 *= _5864;\n    }\n    else\n    {\n        bool _5875 = _5850.type != 0;\n        bool _5881;\n        if (_5875)\n        {\n            _5881 = _8948 > 0.0f;\n        }\n        else\n        {\n            _5881 = _5875;\n        }\n        if (_5881)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _5850.direction;\n            float _5900 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8949 = _5900;\n            _8947 *= _5900;\n        }\n    }\n    bool _5910 = _654_fa_ct_a.x > 0.5f;\n    bool _5916;\n    if (_5910)\n    {\n        _5916 = _8948 > 0.0f;\n    }\n    else\n    {\n        _5916 = _5910;\n    }\n    if (_5916)\n    {\n        float _5923;\n        if (_5853)\n        {\n            _5923 = 1000000000.0f;\n        }\n        else\n        {\n            _5923 = _5850._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _5850.direction;\n        float param_18 = _5923;\n        float _5941 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8949 *= _5941;\n        _8947 *= _5941;\n    }\n    float _5954 = _8948;\n    float _5955 = _5954 * _5824;\n    _8948 = _5955;\n    float3 _5959 = _8947;\n    float3 _5960 = _5959 * _5824;\n    _8947 = _5960;\n    LightSample _8964 = { _5850.direction, _5960, _5955, _8949, _5850._distance, _5850.type };\n    return _8964;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _5994 = v - (n * dot(v, n));\n    float3 t = _5994;\n    float _5998 = dot(_5994, _5994);\n    float l2 = _5998;\n    if (_5998 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6008;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6008 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6008 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6008;\n        l2 = dot(_6008, _6008);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6043 = dot(a, a);\n    float _6047 = dot(b, b);\n    if ((_6043 < 1.0000000195414813782625560981111e-24f) || (_6047 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6061 = a * rsqrt(_6043);\n    float3 _6066 = b * rsqrt(_6047);\n    float _6070 = dot(_6061, _6066);\n    float _6073 = abs(_6070);\n    float g = (((((((((((0.0416471660137176513671875f * _6073) - 0.1924748718738555908203125f) * _6073) + 0.4179156124591827392578125f) * _6073) - 0.616057217121124267578125f) * _6073) + 0.777722418308258056640625f) * _6073) - 0.999542415142059326171875f) * _6073) + 1.570791721343994140625f;\n    if (_6070 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6070 * _6070), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6061, _6066) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6130 = a.z > 0.0f;\n    bool _6134 = b.z > 0.0f;\n    if (_6130 && _6134)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6130 != _6134)\n        {\n            float3 _6169 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6169.z = 0.0f;\n            if (_6130)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6169;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6169;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6169;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6169;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6218 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6244 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6270 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6296 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6218;\n    float3 param_1 = _6244;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6244;\n    float3 param_7 = _6270;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6270;\n    float3 param_13 = _6296;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6296;\n    float3 param_19 = _6218;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _6445 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6469 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _6485 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _6445;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _6469;\n    float4 param_9 = m;\n    float3 param_10 = _6445;\n    float3 param_11 = _6469;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _6485;\n    float4 param_14 = m;\n    float3 param_15 = _6445;\n    float3 param_16 = _6485;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6543 = fa_light_base(param);\n    int param_1 = _6543;\n    int param_2 = _6543 + 1;\n    int param_3 = _6543 + 2;\n    int param_4 = _6543 + 4;\n    float4 _6565 = fa_light_texel(param_4);\n    int param_5 = _6543 + 5;\n    float4 _6570 = fa_light_texel(param_5);\n    int param_6 = _6543 + 6;\n    float4 _6575 = fa_light_texel(param_6);\n    float _6576 = _6575.w;\n    float3 _6581 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6583 = _6576 < 1.5f;\n    bool _6590;\n    if (_6583)\n    {\n        _6590 = dot(normalize(fa_light_texel(param_3).xyz), _6581) >= 0.0f;\n    }\n    else\n    {\n        _6590 = _6583;\n    }\n    if (_6590)\n    {\n        return 0.0f.xxx;\n    }\n    bool _6599 = (_6576 > 0.5f) && _6583;\n    float _6603 = _6599 ? 1.0539000034332275390625f : 1.0f;\n    float3 _6606 = _6565.xyz;\n    float _6608 = _6565.w;\n    float3 _6614 = _6570.xyz;\n    float _6616 = _6570.w;\n    float3 up = _6614 * (_6616 * _6603);\n    float _6622;\n    if (_6599)\n    {\n        _6622 = (3.1415927410125732421875f * _6608) * _6608;\n    }\n    else\n    {\n        _6622 = (4.0f * _6608) * _6616;\n    }\n    if (_6576 > 1.5f)\n    {\n        float3 _6648 = cross(_6606, -_6581);\n        float3 perp = _6648;\n        float _6652 = dot(_6648, _6648);\n        float3 _6655;\n        if (_6652 > 1.0000000133514319600180897396058e-10f)\n        {\n            _6655 = perp * rsqrt(_6652);\n        }\n        else\n        {\n            _6655 = _6614;\n        }\n        perp = _6655;\n        up = _6655 * _6616;\n    }\n    float _6676 = max(_6622, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _6686 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _6686;\n    float3 param_10 = n;\n    float3 param_11 = _6581;\n    float3 _6694 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _6686;\n    float3 param_13 = n;\n    float3 param_14 = _6606 * (_6608 * _6603);\n    float3 _6702 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _6686;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _6710 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _6576;\n    float3 param_20 = _6694;\n    float3 param_21 = _6702;\n    float3 param_22 = _6710;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _6729 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _6729;\n    float2 param_26 = _6729 + float2(64.0f, 0.0f);\n    float4 _6739 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6576;\n    float3 param_29 = _6694;\n    float3 param_30 = _6702;\n    float3 param_31 = _6710;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6739.x) + ((f90.xxx - f0) * _6739.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6581, _6581)) + _6676) / _6676) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4886 = 1.0f / alpha;\n    return ((2.0f + _4886) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4886)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4921 = max(dot(L.nc, l), 0.0f);\n    float _4927 = max(dot(L.nc, h), 0.0f);\n    float _4936 = ((_4927 * _4927) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4936) * _4936)) * (0.5f / max(lerp((2.0f * _4921) * L.coat_ndv, _4921 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4921)) * _4921;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6807;\n    if (L.sheen_on)\n    {\n        _6807 = L.sheen_scale;\n    }\n    else\n    {\n        _6807 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6807);\n    float3 _6820 = normalize(l + v);\n    int param_10 = li;\n    float3 _6831 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6840 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6820), 0.0f);\n        float param_13 = _6840;\n        float param_14 = ndv;\n        result += ((L.sheen * _6831) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _6840)) * _6840) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _6820;\n        float param_18 = max(dot(v, _6820), 0.0f);\n        result += (_6831 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4789 = tdh / at;\n    float _4793 = bdh / ab;\n    float _4805 = ((_4789 * _4789) + (_4793 * _4793)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4805) * _4805);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4985 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5064 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5064) * _5064);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4985);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4985));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4195 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4198 = _4195.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4198 * _4198, exp2((-9.27999973297119140625f) * ndv)) * _4198) + _4195.y)) + _4195.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3506;\n    if (lv == 0)\n    {\n        _3506 = 0.0f;\n    }\n    else\n    {\n        _3506 = res + 2.0f;\n    }\n    float _3516;\n    if (lv == 0)\n    {\n        _3516 = 0.0f;\n    }\n    else\n    {\n        _3516 = (res - (res / float(1 << (lv - 1)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3506, _3516)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3561;\n    if (res > 64.5f)\n    {\n        _3561 = 5.0f;\n    }\n    else\n    {\n        _3561 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3576 = clamp(rough, 0.0f, 1.0f) * (_3561 - 1.0f);\n    int _3583 = int(min(floor(_3576), _3561 - 2.0f));\n    float _3588 = _3576 - float(_3583);\n    float3 param = d;\n    float2 _3592 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3583;\n    float2 param_4 = _3592;\n    float3 _3602 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3588 < 0.00200000009499490261077880859375f)\n    {\n        return _3602;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3583 + 1;\n    float2 param_8 = _3592;\n    return lerp(_3602, fa_probe_level(param_5, param_6, param_7, param_8), _3588.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3672 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3679 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3686 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3692 = dot(bx.xyz, d);\n    float _3696 = dot(by.xyz, d);\n    float _3700 = dot(bz.xyz, d);\n    float _3706;\n    if (_3692 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3706 = (1.0f - _3672) / _3692;\n    }\n    else\n    {\n        float _3720;\n        if (_3692 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3720 = ((-1.0f) - _3672) / _3692;\n        }\n        else\n        {\n            _3720 = 1000000015047466219876688855040.0f;\n        }\n        _3706 = _3720;\n    }\n    float tx = _3706;\n    float _3737;\n    if (_3696 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3737 = (1.0f - _3679) / _3696;\n    }\n    else\n    {\n        float _3750;\n        if (_3696 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3750 = ((-1.0f) - _3679) / _3696;\n        }\n        else\n        {\n            _3750 = 1000000015047466219876688855040.0f;\n        }\n        _3737 = _3750;\n    }\n    float ty = _3737;\n    float _3766;\n    if (_3700 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3766 = (1.0f - _3686) / _3700;\n    }\n    else\n    {\n        float _3779;\n        if (_3700 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3779 = ((-1.0f) - _3686) / _3700;\n        }\n        else\n        {\n            _3779 = 1000000015047466219876688855040.0f;\n        }\n        _3766 = _3779;\n    }\n    float _3791 = tx;\n    float _3794 = (_3791 > 0.0f) ? _3791 : 1000000015047466219876688855040.0f;\n    tx = _3794;\n    float _3795 = ty;\n    float _3798 = (_3795 > 0.0f) ? _3795 : 1000000015047466219876688855040.0f;\n    ty = _3798;\n    float _3808 = min(_3794, min(_3798, (_3766 > 0.0f) ? _3766 : 1000000015047466219876688855040.0f));\n    if (_3808 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3824 = (fa_world_pos + (d * _3808)) - posw.xyz;\n    float3 _3829;\n    if (dot(_3824, _3824) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3829 = normalize(_3824);\n    }\n    else\n    {\n        _3829 = d;\n    }\n    return _3829;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3875 = (1.0f - _654_fa_rpa_tile.w) - _654_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3875 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_654_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _654_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3904 = rough * rough;\n            float _3935 = 0.60000002384185791015625f * _3904;\n            base = lerp(lerp(_654_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_654_fa_env_horizon.xyz, _654_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3904)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3935, 0.0500000007450580596923828125f + _3935, d.y).xxx), ((_654_fa_env_sky.xyz + _654_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3904 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3875;\n    }\n    if (_654_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _654_fa_rpa_tile;\n        float4 param_5 = _654_fa_rpa_pos;\n        float4 param_6 = _654_fa_rpa_bx;\n        float4 param_7 = _654_fa_rpa_by;\n        float4 param_8 = _654_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3994 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3994 * _654_fa_rpa_tile.w);\n    }\n    if (_654_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _654_fa_rpb_tile;\n        float4 param_12 = _654_fa_rpb_pos;\n        float4 param_13 = _654_fa_rpb_bx;\n        float4 param_14 = _654_fa_rpb_by;\n        float4 param_15 = _654_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4026 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4026 * _654_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4672;\n        if (L.aniso >= 0.0f)\n        {\n            _4672 = L.b;\n        }\n        else\n        {\n            _4672 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4672, v), _4672), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4705 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4705.x) + (L.f90.xxx * _4705.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4760 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4760.x) + _4760.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4237 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4237.x) + _4237.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_654_fa_ct_a.zw / exp2(float(k)).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_654_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5462 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5466 = fa_xm_origin(param_1);\n    float2 _5472 = (uv * _5462) - 0.5f.xx;\n    float2 _5475 = frac(_5472);\n    float2 _5478 = floor(_5472);\n    float2 param_2 = _5462;\n    float2 param_3 = _5466;\n    float2 param_4 = _5478;\n    float2 param_5 = _5462;\n    float2 param_6 = _5466;\n    float2 param_7 = _5478 + float2(1.0f, 0.0f);\n    float2 param_8 = _5462;\n    float2 param_9 = _5466;\n    float2 param_10 = _5478 + float2(0.0f, 1.0f);\n    float2 param_11 = _5462;\n    float2 param_12 = _5466;\n    float2 param_13 = _5478 + 1.0f.xx;\n    float3 _5520 = _5475.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5520), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5520), _5475.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5539 = max(_654_fa_tr_b.w - 1.0f, 0.0f);\n    float _5543 = clamp(lod, 0.0f, _5539);\n    int _5547 = int(floor(_5543));\n    int param = _5547;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5557 = float(_5547);\n    float _5558 = _5543 - _5557;\n    bool _5560 = _5558 > 0.001000000047497451305389404296875f;\n    bool _5567;\n    if (_5560)\n    {\n        _5567 = _5557 < _5539;\n    }\n    else\n    {\n        _5567 = _5560;\n    }\n    if (_5567)\n    {\n        int param_2 = _5547 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5558.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5593 = fa_env_brdf(param, param_1);\n    float3 through = ((1.0f.xxx - clamp((f0 * _5593.x) + (f90.xxx * _5593.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float _5621 = max(s.thickness, 0.0f);\n    bool _5626 = _5621 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5626)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5621);\n    }\n    bool _5651 = _654_fa_tr_a.w > 1.5f;\n    bool _5658;\n    if (!_5651)\n    {\n        _5658 = _654_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5658 = _5651;\n    }\n    if (_5658)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float3 world = fa_world_pos;\n    if (_5626)\n    {\n        world += (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5621);\n    }\n    float4 _5693 = float4(world, 1.0f);\n    float _5698 = dot(_654_fa_ct_vpw, _5693);\n    float2 uv = 0.5f.xx;\n    if (_5698 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5716 = float2(dot(_654_fa_ct_vpx, _5693), dot(_654_fa_ct_vpy, _5693)) / _5698.xx;\n        float _5724;\n        if (_654_fa_ct_a.y > 0.5f)\n        {\n            _5724 = (_5716.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5724 = 0.5f - (_5716.y * 0.5f);\n        }\n        uv = float2((_5716.x * 0.5f) + 0.5f, _5724);\n    }\n    float2 param_2 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_3 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_654_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2321_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3257 = int(_2321_fa_shadow_cfg.x + 0.5f);\n    float _3267 = dot(world - _2321_fa_shadow_eye.xyz, _2321_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3272 = _3257 > 0;\n    bool _3281;\n    if (_3272)\n    {\n        int param = _3257 - 1;\n        _3281 = _3267 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3281 = _3272;\n    }\n    if (_3281)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3287 = _3257 > 1;\n        bool _3294;\n        if (_3287)\n        {\n            _3294 = _3267 > _2321_fa_shadow_split.x;\n        }\n        else\n        {\n            _3294 = _3287;\n        }\n        if (_3294)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3300 = _3257 > 2;\n        bool _3307;\n        if (_3300)\n        {\n            _3307 = _3267 > _2321_fa_shadow_split.y;\n        }\n        else\n        {\n            _3307 = _3300;\n        }\n        if (_3307)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3313 = _3257 > 3;\n        bool _3320;\n        if (_3313)\n        {\n            _3320 = _3267 > _2321_fa_shadow_split.z;\n        }\n        else\n        {\n            _3320 = _3313;\n        }\n        if (_3320)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _8606 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8606 = -_8606;\n    }\n    float3 _7896 = normalize(_654_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _8619 = { fa_world_pos, _8606, fa_world_tangent, fa_uv, fa_vertex_color, _7896, gl_FrontFacing };\n    SurfaceInput param_1 = _8619;\n    Surface _7904 = fa_standard_surface(param_1);\n    float3 _8637 = _7904.albedo;\n    float _8638 = _7904.alpha;\n    float3 _8639 = _7904.normal;\n    float _8640 = _7904.metallic;\n    float _8641 = _7904.roughness;\n    float _8642 = _7904.occlusion;\n    float3 _8643 = _7904.emission;\n    float _8644 = _7904.clearcoat;\n    float _8645 = _7904.clearcoat_roughness;\n    float3 _8646 = _7904.sheen_color;\n    float _8647 = _7904.sheen_roughness;\n    float _8648 = _7904.anisotropy;\n    float _8649 = _7904.anisotropy_rotation;\n    float _8650 = _7904.specular;\n    float _8651 = _7904.ior;\n    float3 _8652 = _7904.specular_color;\n    float _8653 = _7904.transmission;\n    float _8654 = _7904.thickness;\n    float3 _8655 = _7904.attenuation_color;\n    float _8656 = _7904.attenuation_distance;\n    SurfaceInput _8627 = { fa_world_pos, _8606, fa_world_tangent, fa_uv, fa_vertex_color, _7896, gl_FrontFacing };\n    SurfaceInput param_2 = _8627;\n    Surface param_3 = _7904;\n    surface(param_2, param_3);\n    _8637 = param_3.albedo;\n    _8638 = param_3.alpha;\n    _8639 = param_3.normal;\n    _8640 = param_3.metallic;\n    _8641 = param_3.roughness;\n    _8642 = param_3.occlusion;\n    _8643 = param_3.emission;\n    _8644 = param_3.clearcoat;\n    _8645 = param_3.clearcoat_roughness;\n    _8646 = param_3.sheen_color;\n    _8647 = param_3.sheen_roughness;\n    _8648 = param_3.anisotropy;\n    _8649 = param_3.anisotropy_rotation;\n    _8650 = param_3.specular;\n    _8651 = param_3.ior;\n    _8652 = param_3.specular_color;\n    _8653 = param_3.transmission;\n    _8654 = param_3.thickness;\n    _8655 = param_3.attenuation_color;\n    _8656 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _8606;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8637 = param_6;\n    _8639 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_654_fa_emissive.w > 0.5f)\n    {\n        result = _8637;\n    }\n    else\n    {\n        float3 _7944 = normalize(_8639);\n        float _7951 = clamp(_8640, 0.0f, 1.0f);\n        float _7955 = clamp(_8641, 0.0500000007450580596923828125f, 1.0f);\n        float _7959 = _7955 * _7955;\n        float _7963 = _7959 * _7959;\n        float _7968 = max(dot(_7944, _7896), 9.9999997473787516355514526367188e-05f);\n        float _7974 = 1.0f - _7951;\n        float _7975 = clamp(_8653, 0.0f, 1.0f) * _7974;\n        float3 _7984 = (_8637 * _7974) * (1.0f - _7975);\n        float3 _7991 = lerp(0.039999999105930328369140625f.xxx, _8637, _7951.xxx);\n        float3 f0 = _7991;\n        SurfaceInput _8635 = { fa_world_pos, _8606, fa_world_tangent, fa_uv, fa_vertex_color, _7896, gl_FrontFacing };\n        SurfaceInput param_8 = _8635;\n        Surface _8738 = { _8637, _8638, _8639, _8640, _8641, _8642, _8643, _8644, _8645, _8646, _8647, _8648, _8649, _8650, _8651, _8652, _8653, _8654, _8655, _8656 };\n        Surface param_9 = _8738;\n        float3 param_10 = _7944;\n        float3 param_11 = _7896;\n        float param_12 = _7951;\n        float param_13 = _7955;\n        float3 param_14 = _7991;\n        FaLayers _8007 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _7944;\n        float3 lit = (fa_indirect_diffuse(param_15) * _7984) * _8642;\n        if (_8007.on)\n        {\n            lit *= _8007.base_scale;\n        }\n        int _8029 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8029; ln++)\n        {\n            int param_16 = ln;\n            int _8042 = fa_cl_light(param_16);\n            int param_17 = _8042;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8042;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _8606;\n            LightSample _8058 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8066 = max(dot(_7944, _8058.direction), 0.0f);\n            float _8072 = _8058.attenuation * _8058.shadow;\n            float3 _8077 = normalize(_8058.direction + _7896);\n            float _8082 = max(dot(_7944, _8077), 0.0f);\n            float _8087 = max(dot(_7896, _8077), 0.0f);\n            bool _8094;\n            if (fa_light_is_area)\n            {\n                _8094 = !_8007.on;\n            }\n            else\n            {\n                _8094 = fa_light_is_area;\n            }\n            if (_8094)\n            {\n                int param_21 = _8042;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _7944;\n                float3 param_24 = _7896;\n                float3 param_25 = _7984;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _7955;\n                float param_29 = _7968;\n                float param_30 = _8072;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8007;\n                    int param_32 = _8042;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _7944;\n                    float3 param_35 = _7896;\n                    float3 param_36 = _8058.direction;\n                    float3 param_37 = _7984;\n                    float3 param_38 = f0;\n                    float param_39 = _7955;\n                    float param_40 = _7968;\n                    float param_41 = _8072;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8007.on)\n                    {\n                        FaLayers param_42 = _8007;\n                        float3 param_43 = _7984;\n                        float3 param_44 = f0;\n                        float3 param_45 = _7944;\n                        float3 param_46 = _7896;\n                        float3 param_47 = _8058.direction;\n                        float3 param_48 = _8077;\n                        float param_49 = _8066;\n                        float param_50 = _7968;\n                        float param_51 = _8082;\n                        float param_52 = _8087;\n                        float param_53 = _7959;\n                        float param_54 = _7963;\n                        int param_55 = _8042;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8072));\n                    }\n                    else\n                    {\n                        float _8200 = ((_8082 * _8082) * (_7963 - 1.0f)) + 1.0f;\n                        int param_56 = _8042;\n                        lit += (((_7984 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8087, 5.0f))) * (((_7963 / ((3.1415927410125732421875f * _8200) * _8200)) * (0.5f / max(lerp((2.0f * _8066) * _7968, _8066 + _7968, _7959), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8066))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8066 * _8072));\n                    }\n                }\n            }\n        }\n        if (_8007.on)\n        {\n            FaLayers param_57 = _8007;\n            float3 param_58 = _7944;\n            float3 param_59 = _7896;\n            float3 param_60 = f0;\n            float param_61 = _7955;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8642);\n        }\n        else\n        {\n            float3 param_62 = _7944;\n            float3 param_63 = _7896;\n            float3 param_64 = f0;\n            float param_65 = _7955;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8642);\n        }\n        if (_7975 > 0.0f)\n        {\n            float _8298;\n            if (_8007.on)\n            {\n                _8298 = _8007.f90;\n            }\n            else\n            {\n                _8298 = 1.0f;\n            }\n            float _8306;\n            if (_8007.on)\n            {\n                _8306 = _8007.base_scale;\n            }\n            else\n            {\n                _8306 = 1.0f;\n            }\n            Surface _8759 = { _8637, _8638, _8639, _8640, _8641, _8642, _8643, _8644, _8645, _8646, _8647, _8648, _8649, _8650, _8651, _8652, _8653, _8654, _8655, _8656 };\n            Surface param_66 = _8759;\n            float3 param_67 = _7944;\n            float3 param_68 = _7896;\n            float param_69 = _7955;\n            float3 param_70 = f0;\n            float param_71 = _8298;\n            float param_72 = _8306;\n            float param_73 = _7975;\n            float param_74 = fa_tr_blend;\n            float3 _8330 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _8330;\n        }\n        result = lit;\n    }\n    float3 _8337 = result;\n    float3 _8338 = _8337 + _8643;\n    result = _8338;\n    float3 param_75 = _8338;\n    float3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _8347 = _654_fa_fog.w > 0.0f;\n    bool _8354;\n    if (!_8347)\n    {\n        _8354 = _654_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8354 = _8347;\n    }\n    if (_8354)\n    {\n        float3 _8363 = fa_world_pos - _654_fa_camera_pos.xyz;\n        float _8369 = dot(_8363, _654_fa_fog_c.xyz);\n        bool _8373 = _654_fa_fog_c.w > 0.5f;\n        float _8374;\n        if (_8373)\n        {\n            _8374 = _8369;\n        }\n        else\n        {\n            _8374 = length(_8363);\n        }\n        float _8386 = _8374 - _654_fa_fog_b.x;\n        if (_8386 > 0.0f)\n        {\n            float _8395 = _654_fa_fog.w * _8386;\n            float tau = _8395 * _8395;\n            if (_654_fa_fog_b.y > 0.0f)\n            {\n                float _8411;\n                if (_8373)\n                {\n                    _8411 = fa_world_pos.y - (_654_fa_fog_c.y * _8369);\n                }\n                else\n                {\n                    _8411 = _654_fa_camera_pos.y;\n                }\n                float _8432 = lerp(_8411, fa_world_pos.y, clamp(_654_fa_fog_b.x / _8374, 0.0f, 1.0f));\n                float _8436 = fa_world_pos.y - _8432;\n                float _8441 = _8432 - _654_fa_fog_b.z;\n                float _8446 = fa_world_pos.y - _654_fa_fog_b.z;\n                bool _8449 = _8441 <= 0.0f;\n                bool _8450 = !_8449;\n                bool _8456;\n                if (_8450)\n                {\n                    _8456 = _654_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8456 = _8449;\n                }\n                float _8457;\n                if (_8456)\n                {\n                    _8457 = _654_fa_fog_b.y;\n                }\n                else\n                {\n                    _8457 = _654_fa_fog_b.y * exp(-min(_654_fa_fog_b.w * _8441, 80.0f));\n                }\n                bool _8484;\n                if (_8450)\n                {\n                    _8484 = _654_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8484 = _8449;\n                }\n                float _8485;\n                if (_8484)\n                {\n                    _8485 = _654_fa_fog_b.y * _8441;\n                }\n                else\n                {\n                    _8485 = (_654_fa_fog_b.y * (1.0f - exp(-min(_654_fa_fog_b.w * _8441, 80.0f)))) / _654_fa_fog_b.w;\n                }\n                bool _8510 = _8446 <= 0.0f;\n                bool _8517;\n                if (!_8510)\n                {\n                    _8517 = _654_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8517 = _8510;\n                }\n                float _8518;\n                if (_8517)\n                {\n                    _8518 = _654_fa_fog_b.y * _8446;\n                }\n                else\n                {\n                    _8518 = (_654_fa_fog_b.y * (1.0f - exp(-min(_654_fa_fog_b.w * _8446, 80.0f)))) / _654_fa_fog_b.w;\n                }\n                float _8545;\n                if (abs(_8436) < 0.001000000047497451305389404296875f)\n                {\n                    _8545 = _8457;\n                }\n                else\n                {\n                    _8545 = (_8518 - _8485) / _8436;\n                }\n                tau += (_8386 * max(_8545, 0.0f));\n            }\n            result = lerp(result, _654_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _8581 = 1.0f - fa_tr_blend;\n        result /= _8581.xxx;\n        _8638 *= _8581;\n    }\n    fa_frag_color = float4(result, _8638);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_187",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_231",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_364",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_654",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2321",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _182_fa_view_proj : packoffset(c0);\n    row_major float4x4 _182_fa_light_vp : packoffset(c4);\n    float4 _182_fa_uv_scale : packoffset(c8);\n    float4 _182_fa_time : packoffset(c9);\n    float4 _182_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _286_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _325 = { mul(float4(position, 1.0f), model).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * _182_fa_uv_scale.xy, color, position };\n    return _325;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _77;\n    if (!_62)\n    {\n        _77 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _224 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_224, _182_fa_light_vp).z;\n    fa_pre_r0 = float3(_182_fa_light_vp[0].x, _182_fa_light_vp[1].x, _182_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_182_fa_light_vp[0].y, _182_fa_light_vp[1].y, _182_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_182_fa_light_vp[0].z, _182_fa_light_vp[1].z, _182_fa_light_vp[2].z);\n    gl_Position = mul(_224, _182_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _286_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _233_fa_camera_pos : packoffset(c0);\n    float4 _233_fa_ambient : packoffset(c1);\n    float4 _233_fa_base_color : packoffset(c2);\n    float4 _233_fa_emissive : packoffset(c3);\n    float4 _233_fa_model_emissive : packoffset(c4);\n    float4 _233_fa_pbr : packoffset(c5);\n    float4 _233_fa_maps : packoffset(c6);\n    float4 _233_fa_fog : packoffset(c7);\n    float4 _233_fa_fog_b : packoffset(c8);\n    float4 _233_fa_fog_c : packoffset(c9);\n    float4 _233_fa_counts : packoffset(c10);\n    float4 _233_fa_env_sky : packoffset(c11);\n    float4 _233_fa_env_horizon : packoffset(c12);\n    float4 _233_fa_time : packoffset(c13);\n    float4 _233_fa_cl_vpx : packoffset(c14);\n    float4 _233_fa_cl_vpy : packoffset(c15);\n    float4 _233_fa_cl_vpw : packoffset(c16);\n    float4 _233_fa_cl_fwd : packoffset(c17);\n    float4 _233_fa_cl_grid : packoffset(c18);\n    float4 _233_fa_cl_info : packoffset(c19);\n    float4 _233_fa_layers_a : packoffset(c20);\n    float4 _233_fa_layers_b : packoffset(c21);\n    float4 _233_fa_layers_c : packoffset(c22);\n    float4 _233_fa_layers_d : packoffset(c23);\n    float4 _233_fa_ct_a : packoffset(c24);\n    float4 _233_fa_ct_b : packoffset(c25);\n    float4 _233_fa_ct_vpx : packoffset(c26);\n    float4 _233_fa_ct_vpy : packoffset(c27);\n    float4 _233_fa_ct_vpw : packoffset(c28);\n    float4 _233_fa_ct_fwd : packoffset(c29);\n    float4 _233_fa_tr_a : packoffset(c30);\n    float4 _233_fa_tr_b : packoffset(c31);\n    float4 _233_fa_probe_sh[9] : packoffset(c32);\n    float4 _233_fa_atlas : packoffset(c41);\n    float4 _233_fa_rpa_tile : packoffset(c42);\n    float4 _233_fa_rpa_pos : packoffset(c43);\n    float4 _233_fa_rpa_bx : packoffset(c44);\n    float4 _233_fa_rpa_by : packoffset(c45);\n    float4 _233_fa_rpa_bz : packoffset(c46);\n    float4 _233_fa_rpb_tile : packoffset(c47);\n    float4 _233_fa_rpb_pos : packoffset(c48);\n    float4 _233_fa_rpb_bx : packoffset(c49);\n    float4 _233_fa_rpb_by : packoffset(c50);\n    float4 _233_fa_rpb_bz : packoffset(c51);\n    float4 _233_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _233_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _244 = fa_tex_fix(param_2, param_3);\n    float4 _798 = base_t;\n    _798.x = _244.x;\n    _798.y = _244.y;\n    _798.z = _244.z;\n    base_t = _798;\n    float4 _259 = (_798 * _233_fa_base_color) * i.vertex_color;\n    float3 _753 = i.world_normal;\n    if (_233_fa_maps.z > 0.5f)\n    {\n        float param_4 = _233_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _292 = fa_tex_fix(param_6, param_7);\n        float3 _296 = (_292 * 2.0f) - 1.0f.xxx;\n        float2 _301 = _296.xy * _233_fa_maps.x;\n        float3 _806 = _296;\n        _806.x = _301.x;\n        _806.y = _301.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _806;\n        _753 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _233_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _330 = fa_tex_fix(param_12, param_13);\n    float4 _809 = mrt;\n    _809.x = _330.x;\n    _809.y = _330.y;\n    _809.z = _330.z;\n    mrt = _809;\n    float4 _360 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _233_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _360.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _233_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _402 = fa_tex_fix(param_20, param_21);\n    float _758 = _233_fa_layers_a.x;\n    float _759 = _233_fa_layers_a.y;\n    float _762 = _233_fa_layers_a.z;\n    float _761 = _233_fa_layers_b.w;\n    float _764 = _233_fa_layers_c.x;\n    if (_233_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_233_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _758 *= _372.y;\n            _759 *= _372.z;\n            _761 *= _360.w;\n        }\n        if (_233_fa_layers_c.z > 1.5f)\n        {\n            _762 *= mrt.x;\n            _764 *= mrt.w;\n        }\n    }\n    Surface _791 = { _259.xyz, _259.w, _753, clamp(_233_fa_pbr.x * _330.z, 0.0f, 1.0f), clamp(_233_fa_pbr.y * _330.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_233_fa_maps.y * (_372.x - 1.0f)), _233_fa_emissive.xyz + (_233_fa_model_emissive.xyz * _402), _758, _759, _233_fa_layers_b.xyz, _761, _762, _233_fa_layers_a.w, _764, _233_fa_layers_c.y, _233_fa_layers_d.xyz, _233_fa_tr_a.x, _233_fa_tr_a.y, _233_fa_tr_b.xyz, _233_fa_tr_a.z };\n    return _791;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _648 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _648 = -_648;\n    }\n    float3 _555 = normalize(_233_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _661 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param = _661;\n    SurfaceInput _669 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param_1 = _669;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _570 = normalize(param_2.normal);\n    float3 _585 = normalize(float3(dot(fa_pre_r0, _570), dot(fa_pre_r1, _570), dot(fa_pre_r2, _570)));\n    float _597 = _585.z;\n    float2 e = _585.xy / ((abs(_585.x) + abs(_585.y)) + abs(_597)).xx;\n    if (_597 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_182",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_286",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _187_fa_view_proj : packoffset(c0);\n    row_major float4x4 _187_fa_light_vp : packoffset(c4);\n    float4 _187_fa_uv_scale : packoffset(c8);\n    float4 _187_fa_time : packoffset(c9);\n    float4 _187_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _231_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _398_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_231_fa_joint_rows[_222] * weights[i]);\n        r1 += (_231_fa_joint_rows[_222 + 1] * weights[i]);\n        r2 += (_231_fa_joint_rows[_222 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _445 = { mul(float4(position, 1.0f), model).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * _187_fa_uv_scale.xy, color, position };\n    return _445;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _82;\n    if (!_67)\n    {\n        _82 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _336 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_336, _187_fa_light_vp).z;\n    fa_pre_r0 = float3(_187_fa_light_vp[0].x, _187_fa_light_vp[1].x, _187_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_187_fa_light_vp[0].y, _187_fa_light_vp[1].y, _187_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_187_fa_light_vp[0].z, _187_fa_light_vp[1].z, _187_fa_light_vp[2].z);\n    gl_Position = mul(_336, _187_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _398_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _233_fa_camera_pos : packoffset(c0);\n    float4 _233_fa_ambient : packoffset(c1);\n    float4 _233_fa_base_color : packoffset(c2);\n    float4 _233_fa_emissive : packoffset(c3);\n    float4 _233_fa_model_emissive : packoffset(c4);\n    float4 _233_fa_pbr : packoffset(c5);\n    float4 _233_fa_maps : packoffset(c6);\n    float4 _233_fa_fog : packoffset(c7);\n    float4 _233_fa_fog_b : packoffset(c8);\n    float4 _233_fa_fog_c : packoffset(c9);\n    float4 _233_fa_counts : packoffset(c10);\n    float4 _233_fa_env_sky : packoffset(c11);\n    float4 _233_fa_env_horizon : packoffset(c12);\n    float4 _233_fa_time : packoffset(c13);\n    float4 _233_fa_cl_vpx : packoffset(c14);\n    float4 _233_fa_cl_vpy : packoffset(c15);\n    float4 _233_fa_cl_vpw : packoffset(c16);\n    float4 _233_fa_cl_fwd : packoffset(c17);\n    float4 _233_fa_cl_grid : packoffset(c18);\n    float4 _233_fa_cl_info : packoffset(c19);\n    float4 _233_fa_layers_a : packoffset(c20);\n    float4 _233_fa_layers_b : packoffset(c21);\n    float4 _233_fa_layers_c : packoffset(c22);\n    float4 _233_fa_layers_d : packoffset(c23);\n    float4 _233_fa_ct_a : packoffset(c24);\n    float4 _233_fa_ct_b : packoffset(c25);\n    float4 _233_fa_ct_vpx : packoffset(c26);\n    float4 _233_fa_ct_vpy : packoffset(c27);\n    float4 _233_fa_ct_vpw : packoffset(c28);\n    float4 _233_fa_ct_fwd : packoffset(c29);\n    float4 _233_fa_tr_a : packoffset(c30);\n    float4 _233_fa_tr_b : packoffset(c31);\n    float4 _233_fa_probe_sh[9] : packoffset(c32);\n    float4 _233_fa_atlas : packoffset(c41);\n    float4 _233_fa_rpa_tile : packoffset(c42);\n    float4 _233_fa_rpa_pos : packoffset(c43);\n    float4 _233_fa_rpa_bx : packoffset(c44);\n    float4 _233_fa_rpa_by : packoffset(c45);\n    float4 _233_fa_rpa_bz : packoffset(c46);\n    float4 _233_fa_rpb_tile : packoffset(c47);\n    float4 _233_fa_rpb_pos : packoffset(c48);\n    float4 _233_fa_rpb_bx : packoffset(c49);\n    float4 _233_fa_rpb_by : packoffset(c50);\n    float4 _233_fa_rpb_bz : packoffset(c51);\n    float4 _233_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _233_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _244 = fa_tex_fix(param_2, param_3);\n    float4 _798 = base_t;\n    _798.x = _244.x;\n    _798.y = _244.y;\n    _798.z = _244.z;\n    base_t = _798;\n    float4 _259 = (_798 * _233_fa_base_color) * i.vertex_color;\n    float3 _753 = i.world_normal;\n    if (_233_fa_maps.z > 0.5f)\n    {\n        float param_4 = _233_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _292 = fa_tex_fix(param_6, param_7);\n        float3 _296 = (_292 * 2.0f) - 1.0f.xxx;\n        float2 _301 = _296.xy * _233_fa_maps.x;\n        float3 _806 = _296;\n        _806.x = _301.x;\n        _806.y = _301.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _806;\n        _753 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _233_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _330 = fa_tex_fix(param_12, param_13);\n    float4 _809 = mrt;\n    _809.x = _330.x;\n    _809.y = _330.y;\n    _809.z = _330.z;\n    mrt = _809;\n    float4 _360 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _233_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _360.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _233_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _402 = fa_tex_fix(param_20, param_21);\n    float _758 = _233_fa_layers_a.x;\n    float _759 = _233_fa_layers_a.y;\n    float _762 = _233_fa_layers_a.z;\n    float _761 = _233_fa_layers_b.w;\n    float _764 = _233_fa_layers_c.x;\n    if (_233_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_233_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _758 *= _372.y;\n            _759 *= _372.z;\n            _761 *= _360.w;\n        }\n        if (_233_fa_layers_c.z > 1.5f)\n        {\n            _762 *= mrt.x;\n            _764 *= mrt.w;\n        }\n    }\n    Surface _791 = { _259.xyz, _259.w, _753, clamp(_233_fa_pbr.x * _330.z, 0.0f, 1.0f), clamp(_233_fa_pbr.y * _330.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_233_fa_maps.y * (_372.x - 1.0f)), _233_fa_emissive.xyz + (_233_fa_model_emissive.xyz * _402), _758, _759, _233_fa_layers_b.xyz, _761, _762, _233_fa_layers_a.w, _764, _233_fa_layers_c.y, _233_fa_layers_d.xyz, _233_fa_tr_a.x, _233_fa_tr_a.y, _233_fa_tr_b.xyz, _233_fa_tr_a.z };\n    return _791;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _648 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _648 = -_648;\n    }\n    float3 _555 = normalize(_233_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _661 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param = _661;\n    SurfaceInput _669 = { fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing };\n    SurfaceInput param_1 = _669;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _570 = normalize(param_2.normal);\n    float3 _585 = normalize(float3(dot(fa_pre_r0, _570), dot(fa_pre_r1, _570), dot(fa_pre_r2, _570)));\n    float _597 = _585.z;\n    float2 e = _585.xy / ((abs(_585.x) + abs(_585.y)) + abs(_597)).xx;\n    if (_597 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_187",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_231",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_398",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _173_fa_view_proj : packoffset(c0);\n    row_major float4x4 _173_fa_light_vp : packoffset(c4);\n    float4 _173_fa_uv_scale : packoffset(c8);\n    float4 _173_fa_time : packoffset(c9);\n    float4 _173_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _190_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _115 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _115) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _277 = { mul(float4(position, 1.0f), model).xyz, (((_115 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * _173_fa_uv_scale.xy, color, position };\n    return _277;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _53 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _68;\n    if (!_53)\n    {\n        _68 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _68 = _53;\n    }\n    if (_68)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = _190_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _173_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_173",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_190",
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _178_fa_view_proj : packoffset(c0);\n    row_major float4x4 _178_fa_light_vp : packoffset(c4);\n    float4 _178_fa_uv_scale : packoffset(c8);\n    float4 _178_fa_time : packoffset(c9);\n    float4 _178_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _222_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _302_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _213 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_222_fa_joint_rows[_213] * weights[i]);\n        r1 += (_222_fa_joint_rows[_213 + 1] * weights[i]);\n        r2 += (_222_fa_joint_rows[_213 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _120 = cross(model[1].xyz, model[2].xyz);\n    float _124 = (dot(model[0].xyz, _120) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _397 = { mul(float4(position, 1.0f), model).xyz, (((_120 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _124, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _124), texcoord0 * _178_fa_uv_scale.xy, color, position };\n    return _397;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _58 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _73;\n    if (!_58)\n    {\n        _73 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _73 = _58;\n    }\n    if (_73)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _302_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _178_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "inst_name": "_178",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_222",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_302",
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          }
        ]
      }
    }
  }
}
