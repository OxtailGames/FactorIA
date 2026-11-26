{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "fb558641ba41b387123470d76b096bf8c235ebdf6b030355e6627097d00c66b9",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _4525[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _650_fa_camera_pos : packoffset(c0);\n    float4 _650_fa_ambient : packoffset(c1);\n    float4 _650_fa_base_color : packoffset(c2);\n    float4 _650_fa_emissive : packoffset(c3);\n    float4 _650_fa_model_emissive : packoffset(c4);\n    float4 _650_fa_pbr : packoffset(c5);\n    float4 _650_fa_maps : packoffset(c6);\n    float4 _650_fa_fog : packoffset(c7);\n    float4 _650_fa_fog_b : packoffset(c8);\n    float4 _650_fa_fog_c : packoffset(c9);\n    float4 _650_fa_counts : packoffset(c10);\n    float4 _650_fa_env_sky : packoffset(c11);\n    float4 _650_fa_env_horizon : packoffset(c12);\n    float4 _650_fa_time : packoffset(c13);\n    float4 _650_fa_cl_vpx : packoffset(c14);\n    float4 _650_fa_cl_vpy : packoffset(c15);\n    float4 _650_fa_cl_vpw : packoffset(c16);\n    float4 _650_fa_cl_fwd : packoffset(c17);\n    float4 _650_fa_cl_grid : packoffset(c18);\n    float4 _650_fa_cl_info : packoffset(c19);\n    float4 _650_fa_layers_a : packoffset(c20);\n    float4 _650_fa_layers_b : packoffset(c21);\n    float4 _650_fa_layers_c : packoffset(c22);\n    float4 _650_fa_layers_d : packoffset(c23);\n    float4 _650_fa_ct_a : packoffset(c24);\n    float4 _650_fa_ct_b : packoffset(c25);\n    float4 _650_fa_ct_vpx : packoffset(c26);\n    float4 _650_fa_ct_vpy : packoffset(c27);\n    float4 _650_fa_ct_vpw : packoffset(c28);\n    float4 _650_fa_ct_fwd : packoffset(c29);\n    float4 _650_fa_tr_a : packoffset(c30);\n    float4 _650_fa_tr_b : packoffset(c31);\n    float4 _650_fa_probe_sh[9] : packoffset(c32);\n    float4 _650_fa_atlas : packoffset(c41);\n    float4 _650_fa_rpa_tile : packoffset(c42);\n    float4 _650_fa_rpa_pos : packoffset(c43);\n    float4 _650_fa_rpa_bx : packoffset(c44);\n    float4 _650_fa_rpa_by : packoffset(c45);\n    float4 _650_fa_rpa_bz : packoffset(c46);\n    float4 _650_fa_rpb_tile : packoffset(c47);\n    float4 _650_fa_rpb_pos : packoffset(c48);\n    float4 _650_fa_rpb_bx : packoffset(c49);\n    float4 _650_fa_rpb_by : packoffset(c50);\n    float4 _650_fa_rpb_bz : packoffset(c51);\n    float4 _650_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2312_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2312_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2312_fa_shadow_info[4] : packoffset(c20);\n    float4 _2312_fa_shadow_split : packoffset(c24);\n    float4 _2312_fa_shadow_cfg : packoffset(c25);\n    float4 _2312_fa_shadow_bias : packoffset(c26);\n    float4 _2312_fa_shadow_eye : packoffset(c27);\n    float4 _2312_fa_shadow_fwd : packoffset(c28);\n    float4 _2312_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1588 = _650_fa_cl_info.x < 0.0f;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = _650_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    bool _1603;\n    if (!_1595)\n    {\n        _1603 = _650_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1603 = _1595;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = _650_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = _650_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1627 = float4(world_pos, 1.0f);\n    float _1633 = dot(_650_fa_cl_vpw, _1627);\n    if (!(_1633 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1655 = float2(dot(_650_fa_cl_vpx, _1627), dot(_650_fa_cl_vpy, _1627)) / _1633.xx;\n    int _1659 = int(_650_fa_cl_grid.x);\n    int _1663 = int(_650_fa_cl_grid.y);\n    int param = (int(_650_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_650_fa_cl_fwd.xyz, world_pos) + _650_fa_cl_fwd.w, _650_fa_cl_grid.w) / _650_fa_cl_grid.w) * _650_fa_cl_grid.z)), 0, int(_650_fa_cl_info.y) - 1) * _1663) + clamp(int(floor(((_1655.y * 0.5f) + 0.5f) * _650_fa_cl_grid.y)), 0, _1663 - 1)) * _1659)) + clamp(int(floor(((_1655.x * 0.5f) + 0.5f) * _650_fa_cl_grid.x)), 0, _1659 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1739 = fa_cluster_texel(param);\n    return int2(int(_1739.x), int(_1739.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_650_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6159 = fa_cluster_lookup(param);\n    fa_cl_slot = _6159.x;\n    fa_cl_local = _6159.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7333 = fa_linear_to_srgb(param);\n        c = _7333;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7341 = fa_srgb_to_linear(param_1);\n            c = _7341;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _532;\n    if (i.front_facing)\n    {\n        _532 = i.world_normal;\n    }\n    else\n    {\n        _532 = -i.world_normal;\n    }\n    float3 _556 = normalize(i.world_tangent.xyz - (_532 * dot(_532, i.world_tangent.xyz)));\n    float3 _583 = normalize(((_556 * m.x) + ((cross(_532, _556) * i.world_tangent.w) * m.y)) + (_532 * m.z));\n    float3 _586;\n    if (i.front_facing)\n    {\n        _586 = _583;\n    }\n    else\n    {\n        _586 = -_583;\n    }\n    return _586;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w);\n    float param = _650_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7373 = fa_tex_fix(param_2, param_3);\n    float4 _9664 = base_t;\n    _9664.x = _7373.x;\n    _9664.y = _7373.y;\n    _9664.z = _7373.z;\n    base_t = _9664;\n    float4 _7387 = (_9664 * _650_fa_base_color) * i.vertex_color;\n    float3 _9424 = i.world_normal;\n    if (_650_fa_maps.z > 0.5f)\n    {\n        float param_4 = _650_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7421 = fa_tex_fix(param_6, param_7);\n        float3 _7424 = (_7421 * 2.0f) - 1.0f.xxx;\n        float2 _7429 = _7424.xy * _650_fa_maps.x;\n        float3 _9672 = _7424;\n        _9672.x = _7429.x;\n        _9672.y = _7429.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9672;\n        _9424 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w);\n    float param_10 = _650_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7459 = fa_tex_fix(param_12, param_13);\n    float4 _9675 = mrt;\n    _9675.x = _7459.x;\n    _9675.y = _7459.y;\n    _9675.z = _7459.z;\n    mrt = _9675;\n    float4 _7489 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w);\n    float param_14 = _650_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7489.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7500 = fa_tex_fix(param_16, param_17);\n    float param_18 = _650_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7532 = fa_tex_fix(param_20, param_21);\n    float _9429 = _650_fa_layers_a.x;\n    float _9430 = _650_fa_layers_a.y;\n    float _9433 = _650_fa_layers_a.z;\n    float _9432 = _650_fa_layers_b.w;\n    float _9435 = _650_fa_layers_c.x;\n    if (_650_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_650_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9429 *= _7500.y;\n            _9430 *= _7500.z;\n            _9432 *= _7489.w;\n        }\n        if (_650_fa_layers_c.z > 1.5f)\n        {\n            _9433 *= mrt.x;\n            _9435 *= mrt.w;\n        }\n    }\n    Surface _9462 = { _7387.xyz, _7387.w, _9424, clamp(_650_fa_pbr.x * _7459.z, 0.0f, 1.0f), clamp(_650_fa_pbr.y * _7459.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_650_fa_maps.y * (_7500.x - 1.0f)), _650_fa_emissive.xyz + (_650_fa_model_emissive.xyz * _7532), _9429, _9430, _650_fa_layers_b.xyz, _9432, _9433, _650_fa_layers_a.w, _9435, _650_fa_layers_c.y, _650_fa_layers_d.xyz, _650_fa_tr_a.x, _650_fa_tr_a.y, _650_fa_tr_b.xyz, _650_fa_tr_a.z };\n    return _9462;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1819 = rect.zw - rect.xy;\n    float2 _1823 = _1819 * atlas;\n    float2 _1827 = ddx * _1823;\n    float2 _1831 = ddy * _1823;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1819), clamp(0.5f * log2(max(max(dot(_1827, _1827), dot(_1831, _1831)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1864 = _650_fa_counts.y < 0.5f;\n    bool _1871;\n    if (!_1864)\n    {\n        _1871 = _650_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1871 = _1864;\n    }\n    if (_1871)\n    {\n        return;\n    }\n    float3 _1877 = ddx(world_pos);\n    float3 _1880 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1884 = fa_cluster_texel(param);\n    int _1888 = int(_1884.w);\n    if (_1888 < 1)\n    {\n        return;\n    }\n    int _1898 = int(_650_fa_counts.y + 0.5f);\n    int param_1 = _1898;\n    float4 _1902 = fa_light_texel(param_1);\n    float2 _1905 = _1902.yz;\n    int _1909 = int(_1902.w);\n    int param_2 = _1898 + 1;\n    float4 _1914 = fa_light_texel(param_2);\n    float _1915 = _1914.x;\n    int _1921 = int(_650_fa_counts.w + 0.5f) - 1;\n    int _1925 = int(_1884.z);\n    float3 _2190;\n    for (int k = 0; k < _1888; k++)\n    {\n        int _1938 = _1925 + k;\n        int param_3 = _1909 + (_1938 >> 2);\n        int _1955 = (_1898 + 2) + (int(fa_light_texel(param_3)[_1938 & 3]) * 7);\n        int param_4 = _1955 + 6;\n        float4 _1960 = fa_light_texel(param_4);\n        if (((int(_1960.w + 0.5f) >> _1921) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1955;\n        float4 _1975 = fa_light_texel(param_5);\n        int param_6 = _1955 + 1;\n        float4 _1980 = fa_light_texel(param_6);\n        int param_7 = _1955 + 2;\n        float4 _1985 = fa_light_texel(param_7);\n        float3 _1988 = _1975.xyz;\n        float _1993 = dot(_1988, world_pos) + _1975.w;\n        float3 _1995 = _1980.xyz;\n        float _2000 = dot(_1995, world_pos) + _1980.w;\n        float3 _2002 = _1985.xyz;\n        float _2007 = dot(_2002, world_pos) + _1985.w;\n        bool _2012 = abs(_1993) > 0.5f;\n        bool _2020;\n        if (!_2012)\n        {\n            _2020 = abs(_2000) > 0.5f;\n        }\n        else\n        {\n            _2020 = _2012;\n        }\n        bool _2028;\n        if (!_2020)\n        {\n            _2028 = abs(_2007) > 0.5f;\n        }\n        else\n        {\n            _2028 = _2020;\n        }\n        if (_2028)\n        {\n            continue;\n        }\n        float _2043 = clamp(dot(geo_normal, normalize(_2002)) * _1960.z, 0.0f, 1.0f);\n        if (_2043 <= 0.0f)\n        {\n            continue;\n        }\n        float _2063 = (clamp((0.5f - abs(_2007)) * 10.0f, 0.0f, 1.0f) * _2043) * _1960.x;\n        float2 _2071 = float2(_1993 + 0.5f, 0.5f - _2000);\n        float2 _2081 = float2(dot(_1988, _1877), dot(_1995, _1877));\n        float2 _2091 = float2(dot(_1988, _1880), dot(_1995, _1880));\n        int param_8 = _1955 + 5;\n        float4 _2096 = fa_light_texel(param_8);\n        int param_9 = _1955 + 3;\n        float4 _2101 = fa_light_texel(param_9);\n        int param_10 = _1955 + 4;\n        float4 _2106 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2096.xyz;\n        bool _2116 = _2101.z > _2101.x;\n        if (_2116)\n        {\n            float4 param_11 = _2101;\n            float2 param_12 = _2071;\n            float2 param_13 = _1905;\n            float2 param_14 = _2081;\n            float2 param_15 = _2091;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1915 > 0.5f) && (_1915 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2142 = fa_dc_to_linear(param_16);\n                float4 _9512 = tx;\n                _9512.x = _2142.x;\n                _9512.y = _2142.y;\n                _9512.z = _2142.z;\n                tx = _9512;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2063 * tex_a) * _2096.w, 0.0f, 1.0f).xxx);\n        if (_2106.z > _2106.x)\n        {\n            float4 param_17 = _2106;\n            float2 param_18 = _2071;\n            float2 param_19 = _1905;\n            float2 param_20 = _2081;\n            float2 param_21 = _2091;\n            float4 _2186 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1915 > 1.5f)\n            {\n                float3 param_22 = _2186.xyz;\n                float3 _2196 = fa_dc_to_srgb(param_22);\n                _2190 = _2196;\n            }\n            else\n            {\n                _2190 = _2186.xyz;\n            }\n            float3 _2205 = (_2190 * 2.0f) - 1.0f.xxx;\n            float2 _2210 = _2205.xy * _1960.y;\n            float3 _2232 = (normalize(_1988) * _2210.x) + (normalize(_1995) * _2210.y);\n            float3 _2235 = normalize(normal);\n            normal = normalize(lerp(_2235, normalize((_2235 * max(_2205.z, 0.0500000007450580596923828125f)) + (_2232 - (_2235 * dot(_2235, _2232)))), clamp(_2063 * (_2116 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4450 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4458 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4461 = int(_4450);\n    int _4464 = int(_4458);\n    float _4474 = _4458 - float(_4464);\n    int _4529 = (_4461 * 9) + _4464;\n    int _4549 = ((_4461 + 1) * 9) + _4464;\n    return lerp(lerp(_4525[_4529], _4525[_4529 + 1], _4474), lerp(_4525[_4549], _4525[_4549 + 1], _4474), _4450 - float(_4461));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9347 = false;\n    float _9348 = 1.0f;\n    float _9349 = 1.0f;\n    float _9350 = 1.0f;\n    float _9351 = 0.0f;\n    float _9352 = 0.0f;\n    float _9353 = 0.0f;\n    float _9354 = 0.0f;\n    float _9356 = 1.0f;\n    bool _9357 = false;\n    float3 _9358 = 0.0f.xxx;\n    float _9359 = 1.0f;\n    float _9360 = 1.0f;\n    float _9361 = 1.0f;\n    float _9362 = 0.0f;\n    float _9363 = 0.0f;\n    float3 _9364 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9365 = float3(0.0f, 0.0f, 1.0f);\n    float _9366 = 1.0f;\n    float _9367 = 1.0f;\n    float _4600 = clamp(s.specular, 0.0f, 1.0f);\n    float _4604 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4609 = (_4600 != 1.0f) || (_4604 != 1.5f);\n    bool _4618;\n    if (!_4609)\n    {\n        _4618 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4618 = _4609;\n    }\n    if (_4618)\n    {\n        float _4626 = (_4604 - 1.0f) / (_4604 + 1.0f);\n        f0 = lerp(min((_4626 * _4626).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4600, s.albedo, metallic.xxx);\n        _9348 = lerp(_4600, 1.0f, metallic);\n        _9347 = true;\n    }\n    float _4653 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4653 > 0.0f)\n    {\n        float _4661 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9351 = _4653;\n        _9352 = _4661;\n        float _4668 = _4661 * _4661;\n        _9353 = _4668;\n        _9354 = _4668 * _4668;\n        float _4680 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9356 = _4680;\n        _9349 = 1.0f - (_4653 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4680, 0.0f, 1.0f), 5.0f))));\n        _9347 = true;\n    }\n    float3 _4699 = max(s.sheen_color, 0.0f.xxx);\n    float _4708 = max(_4699.x, max(_4699.y, _4699.z));\n    if (_4708 > 0.0f)\n    {\n        float _4716 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9357 = true;\n        _9358 = _4699;\n        _9359 = _4716;\n        _9360 = _4716 * _4716;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4716;\n        float _4733 = fa_sheen_albedo(param, param_1);\n        _9362 = _4733;\n        _9361 = 1.0f - min(_4708 * _4733, 1.0f);\n        _9347 = true;\n    }\n    _9350 = _9349 * _9361;\n    float _4752 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4752 != 0.0f)\n    {\n        float3 _4767 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4767;\n        if (dot(_4767, _4767) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4779 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4779.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4779.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4779.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4783 = t;\n        float3 _4784 = normalize(_4783);\n        t = _4784;\n        float3 _4809 = normalize((_4784 * cos(s.anisotropy_rotation)) + ((cross(n, _4784) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9364 = _4809;\n        _9365 = cross(n, _4809);\n        float _4819 = roughness * roughness;\n        float _4825 = lerp(_4819, 1.0f, _4752 * _4752);\n        bool _4827 = _4752 > 0.0f;\n        _9366 = _4827 ? _4825 : _4819;\n        _9367 = _4827 ? _4819 : _4825;\n        _9363 = _4752;\n        _9347 = true;\n    }\n    FaLayers _9389 = { _9347, _9348, _9349, _9350, _9351, _9352, _9353, _9354, i.world_normal, _9356, _9357, _9358, _9359, _9360, _9361, _9362, _9363, _9364, _9365, _9366, _9367 };\n    return _9389;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3678_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3678_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_650_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3619 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3619;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4231 = (1.0f - _650_fa_rpa_tile.w) - _650_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4236 = _650_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4231 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4236)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _650_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4231;\n            }\n        }\n        else\n        {\n            amb = _650_fa_ambient.xyz * _4231;\n        }\n    }\n    bool _4287 = _650_fa_rpa_tile.w > 0.0f;\n    if (_4287)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _650_fa_rpa_tile.xy;\n            float param_4 = _650_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _650_fa_rpa_tile.w);\n        }\n    }\n    bool _4318 = _650_fa_rpb_tile.w > 0.0f;\n    if (_4318)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _650_fa_rpb_tile.xy;\n            float param_7 = _650_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _650_fa_rpb_tile.w);\n        }\n    }\n    if ((_4236 || _4287) || _4318)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3639 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3642 = _3639.x;\n    float _3644 = _3639.z;\n    float2 e = float2(_3642, _3644);\n    if (_3639.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3644)) * ((_3642 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3642)) * ((_3644 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7642 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7647 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7652 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7657 = fa_light_texel(param_3);\n    bool _7660 = _7657.z < 0.5f;\n    bool _7668;\n    if (!_7660)\n    {\n        _7668 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7668 = _7660;\n    }\n    if (_7668)\n    {\n        return 0.0f.xxx;\n    }\n    float _7675 = max(_7642.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7678 = _7647.xyz;\n    float3 _7682 = _7642.xyz;\n    float3 _7686 = (fa_world_pos - _7682) / _7675.xxx;\n    float3 _7695 = min(_7686 + 0.5f.xxx, (_7678 - 0.5f.xxx) - _7686);\n    float _7704 = min(_7695.x, min(_7695.y, _7695.z));\n    if (!(_7704 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7719 = _7678 - 1.0f.xxx;\n    float3 _7720 = clamp(_7686, 0.0f.xxx, _7719);\n    float3 _7728 = min(floor(_7720), max(_7678 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7732 = _7720 - _7728;\n    float3 _7743 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7675));\n    int _7748 = int(_7652.y + 0.5f);\n    float _7753 = 0.3257350027561187744140625f * n.y;\n    float _7757 = 0.3257350027561187744140625f * n.z;\n    float _7761 = 0.3257350027561187744140625f * n.x;\n    float _7768 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _7775 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _7784 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _7791 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _7804 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _7811 = 8 + int(_7657.w);\n    float _7838;\n    float _7851;\n    float _7865;\n    for (int k = 0; k < _7811; k++)\n    {\n        float _7824 = float(k & 1);\n        float _7828 = float((k >> 1) & 1);\n        float _7832 = float((k >> 2) & 1);\n        if (_7824 > 0.5f)\n        {\n            _7838 = _7732.x;\n        }\n        else\n        {\n            _7838 = 1.0f - _7732.x;\n        }\n        if (_7828 > 0.5f)\n        {\n            _7851 = _7732.y;\n        }\n        else\n        {\n            _7851 = 1.0f - _7732.y;\n        }\n        if (_7832 > 0.5f)\n        {\n            _7865 = _7732.z;\n        }\n        else\n        {\n            _7865 = 1.0f - _7732.z;\n        }\n        float _7875 = (_7838 * _7851) * _7865;\n        if (!(_7875 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7888 = min(_7728 + float3(_7824, _7828, _7832), _7719);\n        int _7908 = int(((_7652.x + _7888.x) + (_7647.x * (_7888.y + (_7647.y * _7888.z)))) + 0.5f);\n        float2 _7923 = float2(float(_7908 % _7748) * 10.0f, 1024.0f + (float(_7908 / _7748) * 11.0f));\n        float2 param_4 = _7923 + float2(9.5f, 10.5f);\n        float4 _7931 = fa_gi_fetch(param_4);\n        bool _7934 = _7931.y < 0.5f;\n        bool _7943;\n        if (!_7934)\n        {\n            _7943 = _7931.x > _7657.y;\n        }\n        else\n        {\n            _7943 = _7934;\n        }\n        if (_7943)\n        {\n            continue;\n        }\n        float3 _7955 = _7743 - (_7682 + (_7888 * _7675));\n        float _7958 = length(_7955);\n        float3 _7964 = _7955 / max(_7958, 9.9999997473787516355514526367188e-05f).xxx;\n        float _7974 = max(9.9999997473787516355514526367188e-05f, (dot(-_7964, n) + 1.0f) * 0.5f);\n        float w = _7875 * (_7974 * _7974);\n        float3 param_5 = _7964;\n        float2 param_6 = (_7923 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _7993 = fa_gi_fetch(param_6);\n        float _8000 = _7958 / max(_7652.z, 9.9999997473787516355514526367188e-05f);\n        float _8003 = _7993.x;\n        if (_8000 > _8003)\n        {\n            float _8016 = max(_7993.y - (_8003 * _8003), 0.0f);\n            float _8021 = _8000 - _8003;\n            float _8030 = _8016 / max(_8016 + (_8021 * _8021), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8030 * _8030) * _8030);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _7923 + float2(0.5f, 10.5f);\n        float2 param_8 = _7923 + float2(1.5f, 10.5f);\n        float2 param_9 = _7923 + float2(2.5f, 10.5f);\n        float2 param_10 = _7923 + float2(3.5f, 10.5f);\n        float2 param_11 = _7923 + float2(4.5f, 10.5f);\n        float2 param_12 = _7923 + float2(5.5f, 10.5f);\n        float2 param_13 = _7923 + float2(6.5f, 10.5f);\n        float2 param_14 = _7923 + float2(7.5f, 10.5f);\n        float2 param_15 = _7923 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _7753)) + (fa_gi_fetch(param_9).xyz * _7757)) + (fa_gi_fetch(param_10).xyz * _7761)) + (fa_gi_fetch(param_11).xyz * _7768)) + (fa_gi_fetch(param_12).xyz * _7775)) + (fa_gi_fetch(param_13).xyz * _7784)) + (fa_gi_fetch(param_14).xyz * _7791)) + (fa_gi_fetch(param_15).xyz * _7804)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7704 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8155;\n    if (_650_fa_gi.z > 0.5f)\n    {\n        _8155 = _7657.x;\n    }\n    else\n    {\n        _8155 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7652.w * _8155);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8179 = normalize(_650_fa_camera_pos.xyz - fa_world_pos);\n    int _8184 = int(_650_fa_gi.x + 0.5f);\n    int _8189 = int(_650_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8189) && (k < 8); k++)\n    {\n        int param = _8184 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8179;\n        float3 _8214 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8219 = param_3 * left;\n        acc += (_8214 * _8219);\n        left -= _8219;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_650_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8248 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8248;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_650_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _650_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_650_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_650_fa_cl_info.x) + int(_650_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_650_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6129;\n    if (fa_lm.z > 0.5f)\n    {\n        _6129 = 0.0f;\n    }\n    else\n    {\n        _6129 = 1.0f - clamp(_650_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6140 = _6129 < 1.0f;\n    bool _6146;\n    if (_6140)\n    {\n        int param = li;\n        _6146 = fa_light_baked(param);\n    }\n    else\n    {\n        _6146 = _6140;\n    }\n    return _6146 ? _6129 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _718_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _718_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _837 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _850 = (c - (ru * hx)) - p;\n        float3 _856 = ru * (2.0f * hx);\n        float _862 = max(dot(_856, _856), 9.9999999392252902907785028219223e-09f);\n        float _866 = dot(_850, _856);\n        float t = clamp((-_866) / _862, 0.0f, 1.0f);\n        if (_837)\n        {\n            float _881 = dot(r, _856);\n            float _887 = _862 - (_881 * _881);\n            if (abs(_887) > (9.9999997473787516355514526367188e-06f * _862))\n            {\n                t = clamp(((dot(r, _850) * _881) - _866) / _887, 0.0f, 1.0f);\n            }\n        }\n        return (p + _850) + (_856 * t);\n    }\n    float3 q = p;\n    float _919 = dot(r, axis);\n    bool _927;\n    if (_837)\n    {\n        _927 = abs(_919) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _927 = _837;\n    }\n    if (_927)\n    {\n        float _937 = dot(c - p, axis) / _919;\n        if (_937 > 0.0f)\n        {\n            q = p + (r * _937);\n        }\n    }\n    float3 _950 = q - c;\n    float2 xy = float2(dot(_950, ru), dot(_950, uu));\n    if (shape > 0.5f)\n    {\n        float _965 = length(xy);\n        if (_965 > hx)\n        {\n            xy *= (hx / _965);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _598 = abs(d);\n    float _600 = _598.x;\n    float _602 = _598.y;\n    bool _603 = _600 >= _602;\n    bool _611;\n    if (_603)\n    {\n        _611 = _600 >= _598.z;\n    }\n    else\n    {\n        _611 = _603;\n    }\n    int _612;\n    if (_611)\n    {\n        _612 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _627;\n        if (_602 >= _598.z)\n        {\n            _627 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _627 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _612 = _627;\n    }\n    return _612;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _757 = dot(d, right);\n    float _761 = dot(d, up);\n    float _772;\n    if (((_757 * _757) + (_761 * _761)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _772 = atan2(_761, _757) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _772 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_772 - floor(_772)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1003 = fa_light_base(param);\n    bool _1007 = _650_fa_ambient.w > 4.5f;\n    int param_1 = _1003;\n    float4 _1011 = fa_light_texel(param_1);\n    int param_2 = _1003 + 1;\n    float4 _1016 = fa_light_texel(param_2);\n    float _1019 = _1016.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1031 = _1007 && (_1019 > 2.5f);\n    fa_light_is_area = _1031;\n    bool _1033 = _1019 < 0.5f;\n    float3 l;\n    if (_1033)\n    {\n        l = normalize(_1011.xyz);\n        if (_1007)\n        {\n            int param_3 = _1003 + 6;\n            float4 _1047 = fa_light_texel(param_3);\n            if (_1047.z > 0.5f)\n            {\n                int param_4 = _1003 + 4;\n                float4 _1057 = fa_light_texel(param_4);\n                int param_5 = _1003 + 5;\n                float4 _1062 = fa_light_texel(param_5);\n                float2 param_6 = _1047.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1057.xyz) * _1057.w, (-dot(world_pos, _1062.xyz)) * _1062.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1092 = _1011.xyz;\n        float3 _1094 = _1092 - world_pos;\n        float3 to_light = _1094;\n        float _1097 = length(_1094);\n        float reach = _1097;\n        bool front = true;\n        if (_1031)\n        {\n            int param_8 = _1003 + 7;\n            reach = max(_1097 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1003 + 4;\n            float4 _1121 = fa_light_texel(param_9);\n            int param_10 = _1003 + 5;\n            float4 _1126 = fa_light_texel(param_10);\n            int param_11 = _1003 + 6;\n            float4 _1131 = fa_light_texel(param_11);\n            float _1132 = _1131.w;\n            int param_12 = _1003 + 2;\n            float3 _1139 = normalize(fa_light_texel(param_12).xyz);\n            bool _1141 = _1132 > 1.5f;\n            bool _1149;\n            if (!_1141)\n            {\n                _1149 = dot(_1139, to_light) < 0.0f;\n            }\n            else\n            {\n                _1149 = _1141;\n            }\n            front = _1149;\n            float3 r = 0.0f.xxx;\n            float3 _1158 = _650_fa_camera_pos.xyz - world_pos;\n            bool _1162 = dot(n, n) > 0.5f;\n            bool _1170;\n            if (_1162)\n            {\n                _1170 = dot(_1158, _1158) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1170 = _1162;\n            }\n            if (_1170)\n            {\n                r = reflect(-normalize(_1158), normalize(n));\n            }\n            float3 param_13 = _1092;\n            float3 param_14 = _1139;\n            float3 param_15 = _1121.xyz;\n            float3 param_16 = _1126.xyz;\n            float param_17 = _1121.w;\n            float param_18 = _1126.w;\n            float param_19 = _1132;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1206 = length(to_light);\n        dist = _1206;\n        l = to_light / max(_1206, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1220 = reach / max(_1011.w, 0.001000000047497451305389404296875f);\n        float _1226 = clamp(1.0f - (_1220 * _1220), 0.0f, 1.0f);\n        float _1228;\n        if (front)\n        {\n            _1228 = _1226 * _1226;\n        }\n        else\n        {\n            _1228 = 0.0f;\n        }\n        atten = _1228;\n        bool _1239 = _1019 < 2.5f;\n        if ((_1019 > 1.5f) && _1239)\n        {\n            int param_22 = _1003 + 2;\n            float4 _1247 = fa_light_texel(param_22);\n            float _1257 = _1247.w;\n            int param_23 = _1003 + 3;\n            float4 _1262 = fa_light_texel(param_23);\n            float _1263 = _1262.x;\n            float cos_inner = _1263;\n            if (_1263 > 1.5f)\n            {\n                cos_inner = lerp(_1257, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1257, cos_inner, dot(-l, normalize(_1247.xyz)));\n        }\n        if (_1007 && (_1019 < 1.5f))\n        {\n            int param_24 = _1003 + 6;\n            float4 _1287 = fa_light_texel(param_24);\n            if (_1287.z > 0.5f)\n            {\n                float3 _1295 = -to_light;\n                int param_25 = _1003 + 4;\n                int param_26 = _1003 + 5;\n                float3 _1309 = fa_light_texel(param_25).xyz;\n                float3 _1313 = fa_light_texel(param_26).xyz;\n                float3 _1322 = float3(dot(_1295, _1309), dot(_1295, _1313), dot(_1295, cross(_1309, _1313)));\n                float3 param_27 = _1322;\n                int _1326 = fa_cube_face(param_27);\n                int param_28 = _1326;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1353 = float2(dot(_1322, cross(param_29, param_30)), dot(_1322, param_30)) / max(dot(_1322, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1357 = _1326 / 3;\n                float2 param_31 = _1287.xy + (float2(float(_1326 - (_1357 * 3)), float(_1357)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1353.x), 0.5f - (0.5f * _1353.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1003 + 7;\n            float4 _1387 = fa_light_texel(param_33);\n            if (_1387.z > 0.5f)\n            {\n                int param_34 = _1003 + 2;\n                int param_35 = _1003 + 4;\n                int param_36 = _1003 + 5;\n                float2 param_37 = _1387.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1007 && _1239)\n            {\n                int param_42 = _1003 + 6;\n                float4 _1434 = fa_light_texel(param_42);\n                int param_43 = _1003 + 7;\n                float4 _1439 = fa_light_texel(param_43);\n                bool _1442 = _1434.z > 0.5f;\n                bool _1449;\n                if (!_1442)\n                {\n                    _1449 = _1439.z > 0.5f;\n                }\n                else\n                {\n                    _1449 = _1442;\n                }\n                if (_1449)\n                {\n                    int param_44 = _1003 + 2;\n                    float4 _1456 = fa_light_texel(param_44);\n                    float3 _1460 = normalize(_1456.xyz);\n                    int param_45 = _1003 + 4;\n                    float4 _1465 = fa_light_texel(param_45);\n                    int param_46 = _1003 + 5;\n                    float4 _1470 = fa_light_texel(param_46);\n                    if (_1442)\n                    {\n                        float3 _1478 = -to_light;\n                        float _1485 = _1456.w;\n                        float _1501 = 0.5f / max(dot(_1478, _1460) * (sqrt(max(1.0f - (_1485 * _1485), 0.0f)) / max(_1485, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1434.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1478, _1465.xyz) * _1501), 0.5f - (dot(_1478, _1470.xyz) * _1501));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1439.z > 0.5f)\n                    {\n                        float2 param_49 = _1439.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1460;\n                        float3 param_52 = _1465.xyz;\n                        float3 param_53 = _1470.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9335 = _1016.xyz * atten;\n    if (_1007)\n    {\n        _9335 *= fa_light_tint;\n    }\n    int _1570;\n    if (_1033)\n    {\n        _1570 = 0;\n    }\n    else\n    {\n        _1570 = ((_1019 > 1.5f) && (_1019 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9346 = { l, _9335, atten, 1.0f, dist, _1570 };\n    return _9346;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2302;\n    if (i == 0)\n    {\n        _2302 = _2312_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2318;\n        if (i == 1)\n        {\n            _2318 = _2312_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2326;\n            if (i == 2)\n            {\n                _2326 = _2312_fa_shadow_split.z;\n            }\n            else\n            {\n                _2326 = _2312_fa_shadow_split.w;\n            }\n            _2318 = _2326;\n        }\n        _2302 = _2318;\n    }\n    return _2302;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2359 = fa_shadow_depth(param, param_1);\n    float _2363;\n    if (conv.x < 0.5f)\n    {\n        _2363 = _2359;\n    }\n    else\n    {\n        _2363 = (conv.y * conv.z) / (conv.z - (_2359 * (conv.z - conv.y)));\n    }\n    return _2363;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2409 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2415 = float2(cos(_2409), sin(_2409));\n    float2 dir = _2415;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2424;\n        if (k < 0.0f)\n        {\n            _2424 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2424 = k;\n        }\n        float _2443 = clamp((_2424 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2462 = sqrt((float(i) + 0.5f) * 0.0625f) * _2443;\n            float2 param_3 = uv + (dir * (_2312_fa_shadow_bias.zw * _2462));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2476 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2476 < (zr - (_2462 * plane)))\n            {\n                sum += _2476;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0f)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0f) * unit) * _2514) / texel_m, 1.5f, 16.0f);\n        dir = _2415;\n    }\n    float lit = 0.0f;\n    int _2540 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2540; i_1++)\n    {\n        float _2559 = sqrt((float(i_1) + 0.5f) / float(_2540)) * radius;\n        float2 param_7 = uv + (dir * (_2312_fa_shadow_bias.zw * _2559));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2559 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2540);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2605 = max(_2312_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2610 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2616 = sqrt(1.0f - (_2610 * _2610));\n    float _2624 = min(_2616 / max(_2610, 0.20000000298023223876953125f), 4.0f);\n    float _2629;\n    if (_2312_fa_shadow_bias.y > 0.0f)\n    {\n        _2629 = _2312_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2629 = 1.5f * _2312_fa_shadow_info[ci].x;\n    }\n    float4 _2654 = mul(float4(world + (n * (_2629 * _2616)), 1.0f), _2312_fa_shadow_mat[ci]);\n    float _2661 = _2654.x;\n    bool _2664 = _2661 < _2312_fa_shadow_rect[ci].x;\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2661 > _2312_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2654.y < _2312_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2654.y > _2312_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2698;\n    if (!_2691)\n    {\n        _2698 = _2654.z > 1.0f;\n    }\n    else\n    {\n        _2698 = _2691;\n    }\n    if (_2698)\n    {\n        return -1.0f;\n    }\n    float _2706;\n    if (_2312_fa_shadow_bias.x > 0.0f)\n    {\n        _2706 = _2312_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2706 = 1.5f * _2312_fa_shadow_info[ci].x;\n    }\n    float2 param = _2654.xy;\n    float4 param_1 = _2312_fa_shadow_rect[ci];\n    float param_2 = _2654.z - ((_2706 * (1.0f + (0.5f * _2624))) / _2605);\n    float param_3 = _2312_fa_shadow_info[ci].x;\n    float param_4 = _2605;\n    float param_5 = _2605 * 0.25f;\n    float param_6 = ((_2312_fa_shadow_info[ci].x * min(_2624, 3.0f)) * 0.5f) / _2605;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2312_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2312_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_650_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3084 = int(_2312_fa_shadow_cfg.x + 0.5f);\n    if (_3084 < 1)\n    {\n        return 1.0f;\n    }\n    float _3099 = dot(world - _2312_fa_shadow_eye.xyz, _2312_fa_shadow_fwd.xyz);\n    int param = _3084 - 1;\n    if (_3099 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3111 = _3084 > 1;\n    bool _3118;\n    if (_3111)\n    {\n        _3118 = _3099 > _2312_fa_shadow_split.x;\n    }\n    else\n    {\n        _3118 = _3111;\n    }\n    if (_3118)\n    {\n        ci = 1;\n    }\n    bool _3122 = _3084 > 2;\n    bool _3129;\n    if (_3122)\n    {\n        _3129 = _3099 > _2312_fa_shadow_split.y;\n    }\n    else\n    {\n        _3129 = _3122;\n    }\n    if (_3129)\n    {\n        ci = 2;\n    }\n    bool _3133 = _3084 > 3;\n    bool _3140;\n    if (_3133)\n    {\n        _3140 = _3099 > _2312_fa_shadow_split.z;\n    }\n    else\n    {\n        _3140 = _3133;\n    }\n    if (_3140)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3151 = min(_3084, 4);\n    float _3192;\n    for (int c = ci; c < _3151; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3171;\n            break;\n        }\n        if (_3171 < 0.0f)\n        {\n            continue;\n        }\n        s = _3171;\n        ci = c;\n        if (_2312_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3192 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3192 = _2312_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3211 = _2312_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3192, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3099 - (fa_shadow_split_at(param_7) - _3211)) / _3211, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3243;\n        if ((ci + 1) < _3084)\n        {\n            _3243 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3243 = 1.0f;\n        }\n        s = lerp(s, _3243, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3348 = _650_fa_ct_b.y > 0.5f;\n    bool _3354;\n    if (_3348)\n    {\n        _3354 = _650_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3354 = _3348;\n    }\n    if (_3354)\n    {\n        float _3368 = dot(_650_fa_ct_fwd.xyz, fa_world_pos) + _650_fa_ct_fwd.w;\n        float _3371 = fwidth(_3368);\n        float4 _3381 = float4(fa_world_pos, 1.0f);\n        float _3387 = dot(_650_fa_ct_vpw, _3381);\n        if (_3387 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3406 = float2(dot(_650_fa_ct_vpx, _3381), dot(_650_fa_ct_vpy, _3381)) / _3387.xx;\n            float _3411 = (_3406.x * 0.5f) + 0.5f;\n            float _3415;\n            if (_650_fa_ct_a.y > 0.5f)\n            {\n                _3415 = (_3406.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3415 = 0.5f - (_3406.y * 0.5f);\n            }\n            bool _3431 = _3411 >= 0.0f;\n            bool _3437;\n            if (_3431)\n            {\n                _3437 = _3411 < 1.0f;\n            }\n            else\n            {\n                _3437 = _3431;\n            }\n            bool _3443;\n            if (_3437)\n            {\n                _3443 = _3415 >= 0.0f;\n            }\n            else\n            {\n                _3443 = _3437;\n            }\n            bool _3449;\n            if (_3443)\n            {\n                _3449 = _3415 < 1.0f;\n            }\n            else\n            {\n                _3449 = _3443;\n            }\n            if (_3449)\n            {\n                float4 _3475 = fa_screen_tex.Load(int3(clamp(int2(float2(_3411, _3415) * _650_fa_ct_a.zw), int2(0, 0), int2(_650_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3478 = _3475.w > 0.5f;\n                bool _3494;\n                if (_3478)\n                {\n                    _3494 = abs(_3368 - _3475.x) <= (((0.00200000009499490261077880859375f * _3368) + 0.00999999977648258209228515625f) + min(1.5f * _3371, 0.100000001490116119384765625f * _3368));\n                }\n                else\n                {\n                    _3494 = _3478;\n                }\n                if (_3494)\n                {\n                    float _3500;\n                    if (_650_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3500 = min(_3475.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3500 = _3475.y;\n                    }\n                    return _3500;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2764 = _650_fa_pbr.z < 0.5f;\n    bool _2771;\n    if (!_2764)\n    {\n        _2771 = _2312_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2771 = _2764;\n    }\n    if (_2771)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2312_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2784 = fa_light_texel(param);\n    float _2785 = _2784.x;\n    if (_2785 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2794 = int(_2785 + 0.5f);\n    int param_1 = _2794;\n    float4 _2798 = fa_light_texel(param_1);\n    int param_2 = _2794 + 1;\n    float4 _2803 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2806 = _2798.y;\n    if (_2806 > 0.0f)\n    {\n        float _2823 = 1.0f - smoothstep(0.75f * _2806, _2806, length(world - _2312_fa_shadow_eye.xyz));\n        fade = _2823;\n        if (_2823 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2798.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2847 = (_2794 + 2) + (face * 6);\n    int param_4 = _2847;\n    int param_5 = _2847 + 1;\n    int param_6 = _2847 + 3;\n    float4 _2861 = fa_light_texel(param_6);\n    int param_7 = _2847 + 4;\n    float4 _2866 = fa_light_texel(param_7);\n    int param_8 = _2847 + 5;\n    float4 _2871 = fa_light_texel(param_8);\n    float _2883 = _2871.x * max(dot(_2861, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2888 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2911 = clamp(dot(n, _2861.xyz), -1.0f, 1.0f);\n    float _2930 = min(sqrt(1.0f - (_2911 * _2911)) / max(abs(dot(n, world - lpos)) / max(dot(_2861, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2933 = _2803.y;\n    float _2935;\n    if (_2933 > 0.0f)\n    {\n        _2935 = _2933;\n    }\n    else\n    {\n        _2935 = 1.5f * _2883;\n    }\n    float4 _2955 = float4(world + (n * (_2935 * sqrt(1.0f - (_2888 * _2888)))), 1.0f);\n    float _2959 = dot(_2861, _2955);\n    float _2962 = _2871.y;\n    if (_2959 < _2962)\n    {\n        return 1.0f;\n    }\n    float2 _2977 = float2(dot(fa_light_texel(param_4), _2955), dot(fa_light_texel(param_5), _2955)) / _2959.xx;\n    float _2979 = _2977.x;\n    bool _2982 = _2979 < _2866.x;\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2979 > _2866.z;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2977.y < _2866.y;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2977.y > _2866.w;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        return 1.0f;\n    }\n    float _3015 = _2803.x;\n    float _3017;\n    if (_3015 > 0.0f)\n    {\n        _3017 = _3015;\n    }\n    else\n    {\n        _3017 = 1.5f * _2883;\n    }\n    float2 param_9 = _2977;\n    float4 param_10 = _2866;\n    float param_11 = _2959 - (_3017 * (1.0f + (0.5f * _2930)));\n    float param_12 = _2883;\n    float param_13 = 1.0f;\n    float param_14 = _2871.z * 0.25f;\n    float param_15 = (_2883 * min(_2930, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2962, _2871.z);\n    int param_17 = int(_2798.z + 0.5f);\n    float param_18 = _2798.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5343 = _650_fa_ct_a.x < 0.5f;\n    bool _5350;\n    if (!_5343)\n    {\n        _5350 = _2312_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5350 = _5343;\n    }\n    if (_5350)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2312_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5363 = fa_light_texel(param);\n    float _5364 = _5363.y;\n    float len = _5364;\n    if (_5364 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5376 = length(world - _650_fa_camera_pos.xyz);\n    float _5385 = 1.0f - smoothstep(0.5f * _650_fa_ct_b.x, _650_fa_ct_b.x, _5376);\n    if (_5385 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5391 = len;\n    float _5394 = min(_5391, 0.89999997615814208984375f * dist);\n    len = _5394;\n    float _5399 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5376);\n    float _5404 = _5399 + (0.5f * _5394);\n    float3 _5410 = world + (gn * _5399);\n    float _5412 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5473;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5427 = (float(k) + _5412) * 0.083333335816860198974609375f;\n        float3 _5435 = _5410 + (l * (_5427 * len));\n        float4 _5441 = float4(_5435, 1.0f);\n        float _5446 = dot(_650_fa_ct_vpw, _5441);\n        if (_5446 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5464 = float2(dot(_650_fa_ct_vpx, _5441), dot(_650_fa_ct_vpy, _5441)) / _5446.xx;\n        float _5468 = _5464.x * 0.5f;\n        float _5469 = _5468 + 0.5f;\n        if (_650_fa_ct_a.y > 0.5f)\n        {\n            _5473 = (_5464.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5473 = 0.5f - (_5464.y * 0.5f);\n        }\n        bool _5489 = _5469 < 0.0f;\n        bool _5496;\n        if (!_5489)\n        {\n            _5496 = _5469 >= 1.0f;\n        }\n        else\n        {\n            _5496 = _5489;\n        }\n        bool _5503;\n        if (!_5496)\n        {\n            _5503 = _5473 < 0.0f;\n        }\n        else\n        {\n            _5503 = _5496;\n        }\n        bool _5510;\n        if (!_5503)\n        {\n            _5510 = _5473 >= 1.0f;\n        }\n        else\n        {\n            _5510 = _5503;\n        }\n        if (_5510)\n        {\n            break;\n        }\n        float4 _5534 = fa_screen_tex.Load(int3(clamp(int2(float2(_5469, _5473) * _650_fa_ct_a.zw), int2(0, 0), int2(_650_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5534.w < 0.5f)\n        {\n            continue;\n        }\n        float _5552 = (dot(_650_fa_ct_fwd.xyz, _5435) + _650_fa_ct_fwd.w) - _5534.x;\n        if ((_5552 > _5399) && (_5552 < _5404))\n        {\n            occ = max(occ, (1.0f - (_5427 * _5427)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5469, 0.5f - _5468), min(_5473, 1.0f - _5473))));\n        }\n    }\n    return 1.0f - (occ * _5385);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6185 = fa_baked_keep(param);\n    if (_6185 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9402 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9402;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6211 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9404 = _6211.color;\n    float _9405 = _6211.attenuation;\n    float _9406 = _6211.shadow;\n    bool _6214 = _6211.type == 0;\n    if (_6214 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6211.direction;\n        float _6225 = fa_shadow_factor(param_5, param_6);\n        _9406 = _6225;\n        _9404 *= _6225;\n    }\n    else\n    {\n        bool _6236 = _6211.type != 0;\n        bool _6242;\n        if (_6236)\n        {\n            _6242 = _9405 > 0.0f;\n        }\n        else\n        {\n            _6242 = _6236;\n        }\n        if (_6242)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6211.direction;\n            float _6261 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9406 = _6261;\n            _9404 *= _6261;\n        }\n    }\n    bool _6271 = _650_fa_ct_a.x > 0.5f;\n    bool _6277;\n    if (_6271)\n    {\n        _6277 = _9405 > 0.0f;\n    }\n    else\n    {\n        _6277 = _6271;\n    }\n    if (_6277)\n    {\n        float _6284;\n        if (_6214)\n        {\n            _6284 = 1000000000.0f;\n        }\n        else\n        {\n            _6284 = _6211._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6211.direction;\n        float param_18 = _6284;\n        float _6302 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9406 *= _6302;\n        _9404 *= _6302;\n    }\n    float _6315 = _9405;\n    float _6316 = _6315 * _6185;\n    _9405 = _6316;\n    float3 _6320 = _9404;\n    float3 _6321 = _6320 * _6185;\n    _9404 = _6321;\n    LightSample _9421 = { _6211.direction, _6321, _6316, _9406, _6211._distance, _6211.type };\n    return _9421;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6355 = v - (n * dot(v, n));\n    float3 t = _6355;\n    float _6359 = dot(_6355, _6355);\n    float l2 = _6359;\n    if (_6359 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6369;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6369 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6369 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6369;\n        l2 = dot(_6369, _6369);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _6756;\n    if ((j == 0) || (j == 7))\n    {\n        _6756 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6766;\n        if ((j == 3) || (j == 4))\n        {\n            _6766 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6766 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6756 = _6766;\n    }\n    float _6787;\n    if ((j == 1) || (j == 2))\n    {\n        _6787 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6796;\n        if ((j == 5) || (j == 6))\n        {\n            _6796 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6796 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6787 = _6796;\n    }\n    return (pc + (ex * _6756)) + (ey * _6787);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6404 = dot(a, a);\n    float _6408 = dot(b, b);\n    if ((_6404 < 1.0000000195414813782625560981111e-24f) || (_6408 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6422 = a * rsqrt(_6404);\n    float3 _6427 = b * rsqrt(_6408);\n    float _6431 = dot(_6422, _6427);\n    float _6434 = abs(_6431);\n    float g = (((((((((((0.0416471660137176513671875f * _6434) - 0.1924748718738555908203125f) * _6434) + 0.4179156124591827392578125f) * _6434) - 0.616057217121124267578125f) * _6434) + 0.777722418308258056640625f) * _6434) - 0.999542415142059326171875f) * _6434) + 1.570791721343994140625f;\n    if (_6431 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6431 * _6431), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6422, _6427) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6491 = a.z > 0.0f;\n    bool _6495 = b.z > 0.0f;\n    if (_6491 && _6495)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6491 != _6495)\n        {\n            float3 _6530 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6530.z = 0.0f;\n            if (_6491)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6530;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6530;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6530;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6530;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6579 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6605 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6631 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6657 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6579;\n    float3 param_1 = _6605;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6605;\n    float3 param_7 = _6631;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6631;\n    float3 param_13 = _6657;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6657;\n    float3 param_19 = _6579;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _6825 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _6843;\n    for (int k = 0; k < (2 * _6825); k++)\n    {\n        bool _6840 = k >= _6825;\n        if (_6840)\n        {\n            _6843 = k - _6825;\n        }\n        else\n        {\n            _6843 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_6825 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6889 = 2 * _6843;\n            int param_4 = _6889 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6889 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6889 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _6926 = _6840.xxxx;\n        float4 param_16 = float4(_6926.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _6926.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _6926.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _6926.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _6937 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6840)\n        {\n            float2 _9647 = sum;\n            _9647.y = _9647.y + _6937;\n            sum = _9647;\n        }\n        else\n        {\n            float2 _9650 = sum;\n            _9650.x = _9650.x + _6937;\n            sum = _9650;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6961 = fa_light_base(param);\n    int param_1 = _6961;\n    int param_2 = _6961 + 1;\n    int param_3 = _6961 + 2;\n    int param_4 = _6961 + 4;\n    float4 _6983 = fa_light_texel(param_4);\n    int param_5 = _6961 + 5;\n    float4 _6988 = fa_light_texel(param_5);\n    int param_6 = _6961 + 6;\n    float4 _6993 = fa_light_texel(param_6);\n    float _6994 = _6993.w;\n    float3 _6999 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7001 = _6994 < 1.5f;\n    bool _7008;\n    if (_7001)\n    {\n        _7008 = dot(normalize(fa_light_texel(param_3).xyz), _6999) >= 0.0f;\n    }\n    else\n    {\n        _7008 = _7001;\n    }\n    if (_7008)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7017 = (_6994 > 0.5f) && _7001;\n    float _7021 = _7017 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7024 = _6983.xyz;\n    float _7026 = _6983.w;\n    float3 _7032 = _6988.xyz;\n    float _7034 = _6988.w;\n    float3 up = _7032 * (_7034 * _7021);\n    float _7040;\n    if (_7017)\n    {\n        _7040 = (3.1415927410125732421875f * _7026) * _7026;\n    }\n    else\n    {\n        _7040 = (4.0f * _7026) * _7034;\n    }\n    if (_6994 > 1.5f)\n    {\n        float3 _7066 = cross(_7024, -_6999);\n        float3 perp = _7066;\n        float _7070 = dot(_7066, _7066);\n        float3 _7073;\n        if (_7070 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7073 = perp * rsqrt(_7070);\n        }\n        else\n        {\n            _7073 = _7032;\n        }\n        perp = _7073;\n        up = _7073 * _7034;\n    }\n    float _7094 = max(_7040, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7104 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7104;\n    float3 param_10 = n;\n    float3 param_11 = _6999;\n    float3 param_12 = _7104;\n    float3 param_13 = n;\n    float3 param_14 = _7024 * (_7026 * _7021);\n    float3 param_15 = _7104;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7135 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7135;\n    float2 param_21 = _7135 + float2(64.0f, 0.0f);\n    float4 _7145 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6994;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7157 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7157.x) + (((f0 * _7145.x) + ((f90.xxx - f0) * _7145.y)) * _7157.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6999, _6999)) + _7094) / _7094) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5080 = 1.0f / alpha;\n    return ((2.0f + _5080) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5080)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5115 = max(dot(L.nc, l), 0.0f);\n    float _5121 = max(dot(L.nc, h), 0.0f);\n    float _5130 = ((_5121 * _5121) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5130) * _5130)) * (0.5f / max(lerp((2.0f * _5115) * L.coat_ndv, _5115 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5115)) * _5115;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7194;\n    if (L.sheen_on)\n    {\n        _7194 = L.sheen_scale;\n    }\n    else\n    {\n        _7194 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7194);\n    float3 _7207 = normalize(l + v);\n    int param = li;\n    float3 _7218 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7227 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7207), 0.0f);\n        float param_3 = _7227;\n        float param_4 = ndv;\n        result += ((L.sheen * _7218) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7227)) * _7227) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7207;\n        float param_8 = max(dot(v, _7207), 0.0f);\n        result += (_7218 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4983 = tdh / at;\n    float _4987 = bdh / ab;\n    float _4999 = ((_4983 * _4983) + (_4987 * _4987)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4999) * _4999);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5179 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5258 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5258) * _5258);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5179);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5179));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4382 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4385 = _4382.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4385 * _4385, exp2((-9.27999973297119140625f) * ndv)) * _4385) + _4382.y)) + _4382.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3691;\n    if (lv == 0)\n    {\n        _3691 = 0.0f;\n    }\n    else\n    {\n        _3691 = res + 2.0f;\n    }\n    float _3701;\n    if (lv == 0)\n    {\n        _3701 = 0.0f;\n    }\n    else\n    {\n        _3701 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3691, _3701)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3747;\n    if (res > 64.5f)\n    {\n        _3747 = 5.0f;\n    }\n    else\n    {\n        _3747 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3762 = clamp(rough, 0.0f, 1.0f) * (_3747 - 1.0f);\n    int _3769 = int(min(floor(_3762), _3747 - 2.0f));\n    float _3774 = _3762 - float(_3769);\n    float3 param = d;\n    float2 _3778 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3769;\n    float2 param_4 = _3778;\n    float3 _3788 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3774 < 0.00200000009499490261077880859375f)\n    {\n        return _3788;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3769 + 1;\n    float2 param_8 = _3778;\n    return lerp(_3788, fa_probe_level(param_5, param_6, param_7, param_8), _3774.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3860 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3867 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3874 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3880 = dot(bx.xyz, d);\n    float _3884 = dot(by.xyz, d);\n    float _3888 = dot(bz.xyz, d);\n    float _3894;\n    if (_3880 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3894 = (1.0f - _3860) / _3880;\n    }\n    else\n    {\n        float _3908;\n        if (_3880 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3908 = ((-1.0f) - _3860) / _3880;\n        }\n        else\n        {\n            _3908 = 1000000015047466219876688855040.0f;\n        }\n        _3894 = _3908;\n    }\n    float tx = _3894;\n    float _3925;\n    if (_3884 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3925 = (1.0f - _3867) / _3884;\n    }\n    else\n    {\n        float _3938;\n        if (_3884 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3938 = ((-1.0f) - _3867) / _3884;\n        }\n        else\n        {\n            _3938 = 1000000015047466219876688855040.0f;\n        }\n        _3925 = _3938;\n    }\n    float ty = _3925;\n    float _3954;\n    if (_3888 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3954 = (1.0f - _3874) / _3888;\n    }\n    else\n    {\n        float _3967;\n        if (_3888 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3967 = ((-1.0f) - _3874) / _3888;\n        }\n        else\n        {\n            _3967 = 1000000015047466219876688855040.0f;\n        }\n        _3954 = _3967;\n    }\n    float _3979 = tx;\n    float _3982 = (_3979 > 0.0f) ? _3979 : 1000000015047466219876688855040.0f;\n    tx = _3982;\n    float _3983 = ty;\n    float _3986 = (_3983 > 0.0f) ? _3983 : 1000000015047466219876688855040.0f;\n    ty = _3986;\n    float _3996 = min(_3982, min(_3986, (_3954 > 0.0f) ? _3954 : 1000000015047466219876688855040.0f));\n    if (_3996 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4012 = (fa_world_pos + (d * _3996)) - posw.xyz;\n    float3 _4017;\n    if (dot(_4012, _4012) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4017 = normalize(_4012);\n    }\n    else\n    {\n        _4017 = d;\n    }\n    return _4017;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4063 = (1.0f - _650_fa_rpa_tile.w) - _650_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4063 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_650_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _650_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4091 = rough * rough;\n            float _4122 = 0.60000002384185791015625f * _4091;\n            base = lerp(lerp(_650_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_650_fa_env_horizon.xyz, _650_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4091)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4122, 0.0500000007450580596923828125f + _4122, d.y).xxx), ((_650_fa_env_sky.xyz + _650_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4091 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4063;\n    }\n    if (_650_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _650_fa_rpa_tile;\n        float4 param_5 = _650_fa_rpa_pos;\n        float4 param_6 = _650_fa_rpa_bx;\n        float4 param_7 = _650_fa_rpa_by;\n        float4 param_8 = _650_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4181 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4181 * _650_fa_rpa_tile.w);\n    }\n    if (_650_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _650_fa_rpb_tile;\n        float4 param_12 = _650_fa_rpb_pos;\n        float4 param_13 = _650_fa_rpb_bx;\n        float4 param_14 = _650_fa_rpb_by;\n        float4 param_15 = _650_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4213 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4213 * _650_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4860;\n        if (L.aniso >= 0.0f)\n        {\n            _4860 = L.b;\n        }\n        else\n        {\n            _4860 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4860, v), _4860), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4896 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4896.x) + (L.f90.xxx * _4896.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4954 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4954.x) + _4954.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4424 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4424.x) + _4424.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_650_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_650_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5656 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5660 = fa_xm_origin(param_1);\n    float2 _5666 = (uv * _5656) - 0.5f.xx;\n    float2 _5669 = frac(_5666);\n    float2 _5672 = floor(_5666);\n    float2 param_2 = _5656;\n    float2 param_3 = _5660;\n    float2 param_4 = _5672;\n    float2 param_5 = _5656;\n    float2 param_6 = _5660;\n    float2 param_7 = _5672 + float2(1.0f, 0.0f);\n    float2 param_8 = _5656;\n    float2 param_9 = _5660;\n    float2 param_10 = _5672 + float2(0.0f, 1.0f);\n    float2 param_11 = _5656;\n    float2 param_12 = _5660;\n    float2 param_13 = _5672 + 1.0f.xx;\n    float3 _5714 = _5669.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5714), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5714), _5669.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5733 = max(_650_fa_tr_b.w - 1.0f, 0.0f);\n    float _5737 = clamp(lod, 0.0f, _5733);\n    int _5741 = int(floor(_5737));\n    int param = _5741;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5751 = float(_5741);\n    float _5752 = _5737 - _5751;\n    bool _5754 = _5752 > 0.001000000047497451305389404296875f;\n    bool _5761;\n    if (_5754)\n    {\n        _5761 = _5751 < _5733;\n    }\n    else\n    {\n        _5761 = _5754;\n    }\n    if (_5761)\n    {\n        int param_2 = _5741 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5752.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5787 = fa_env_brdf(param, param_1);\n    float3 _5811 = ((1.0f.xxx - clamp((f0 * _5787.x) + (f90.xxx * _5787.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _5811;\n    float _5817 = max(s.thickness, 0.0f);\n    bool _5822 = _5817 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5822)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5817);\n    }\n    bool _5847 = _650_fa_tr_a.w > 1.5f;\n    bool _5853;\n    if (_5847)\n    {\n        _5853 = _650_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _5853 = _5847;\n    }\n    bool _5860;\n    if (!_5853)\n    {\n        _5860 = _650_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5860 = _5853;\n    }\n    if (_5860)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _5875 = float4(fa_world_pos, 1.0f);\n    float _5880 = dot(_650_fa_ct_vpw, _5875);\n    float2 uv0 = 0.5f.xx;\n    if (_5880 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5898 = float2(dot(_650_fa_ct_vpx, _5875), dot(_650_fa_ct_vpy, _5875)) / _5880.xx;\n        float _5906;\n        if (_650_fa_ct_a.y > 0.5f)\n        {\n            _5906 = (_5898.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5906 = 0.5f - (_5898.y * 0.5f);\n        }\n        uv0 = float2((_5898.x * 0.5f) + 0.5f, _5906);\n    }\n    if (_650_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _5927 = fa_xm_size(param_2);\n        float2 _5935 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _5927);\n        if (fa_screen_tex.Load(int3(int2(_5935), 0)).w > 0.5f)\n        {\n            int _5955 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _5978 = abs(dx) > _5955;\n                    bool _5986;\n                    if (!_5978)\n                    {\n                        _5986 = abs(dy) > _5955;\n                    }\n                    else\n                    {\n                        _5986 = _5978;\n                    }\n                    if (_5986)\n                    {\n                        continue;\n                    }\n                    float4 _6007 = fa_screen_tex.Load(int3(int2(clamp(_5935 + float2(float(dx), float(dy)), 0.0f.xx, _5927 - 1.0f.xx)), 0));\n                    if (_6007.w > 0.5f)\n                    {\n                        acc += _6007.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _5811 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_5822)\n    {\n        float4 _6055 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5817), 1.0f);\n        float _6060 = dot(_650_fa_ct_vpw, _6055);\n        uv = 0.5f.xx;\n        if (_6060 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6077 = float2(dot(_650_fa_ct_vpx, _6055), dot(_650_fa_ct_vpy, _6055)) / _6060.xx;\n            float _6085;\n            if (_650_fa_ct_a.y > 0.5f)\n            {\n                _6085 = (_6077.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6085 = 0.5f - (_6077.y * 0.5f);\n            }\n            uv = float2((_6077.x * 0.5f) + 0.5f, _6085);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_650_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2312_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3271 = int(_2312_fa_shadow_cfg.x + 0.5f);\n    float _3281 = dot(world - _2312_fa_shadow_eye.xyz, _2312_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3286 = _3271 > 0;\n    bool _3295;\n    if (_3286)\n    {\n        int param = _3271 - 1;\n        _3295 = _3281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3295 = _3286;\n    }\n    if (_3295)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3301 = _3271 > 1;\n        bool _3308;\n        if (_3301)\n        {\n            _3308 = _3281 > _2312_fa_shadow_split.x;\n        }\n        else\n        {\n            _3308 = _3301;\n        }\n        if (_3308)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3314 = _3271 > 2;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3281 > _2312_fa_shadow_split.y;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3327 = _3271 > 3;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3281 > _2312_fa_shadow_split.z;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _9063 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9063 = -_9063;\n    }\n    float3 _8356 = normalize(_650_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9076 = { fa_world_pos, _9063, fa_world_tangent, fa_uv, fa_vertex_color, _8356, gl_FrontFacing };\n    SurfaceInput param_1 = _9076;\n    Surface _8364 = fa_standard_surface(param_1);\n    float3 _9094 = _8364.albedo;\n    float _9095 = _8364.alpha;\n    float3 _9096 = _8364.normal;\n    float _9097 = _8364.metallic;\n    float _9098 = _8364.roughness;\n    float _9099 = _8364.occlusion;\n    float3 _9100 = _8364.emission;\n    float _9101 = _8364.clearcoat;\n    float _9102 = _8364.clearcoat_roughness;\n    float3 _9103 = _8364.sheen_color;\n    float _9104 = _8364.sheen_roughness;\n    float _9105 = _8364.anisotropy;\n    float _9106 = _8364.anisotropy_rotation;\n    float _9107 = _8364.specular;\n    float _9108 = _8364.ior;\n    float3 _9109 = _8364.specular_color;\n    float _9110 = _8364.transmission;\n    float _9111 = _8364.thickness;\n    float3 _9112 = _8364.attenuation_color;\n    float _9113 = _8364.attenuation_distance;\n    SurfaceInput _9084 = { fa_world_pos, _9063, fa_world_tangent, fa_uv, fa_vertex_color, _8356, gl_FrontFacing };\n    SurfaceInput param_2 = _9084;\n    Surface param_3 = _8364;\n    surface(param_2, param_3);\n    _9094 = param_3.albedo;\n    _9095 = param_3.alpha;\n    _9096 = param_3.normal;\n    _9097 = param_3.metallic;\n    _9098 = param_3.roughness;\n    _9099 = param_3.occlusion;\n    _9100 = param_3.emission;\n    _9101 = param_3.clearcoat;\n    _9102 = param_3.clearcoat_roughness;\n    _9103 = param_3.sheen_color;\n    _9104 = param_3.sheen_roughness;\n    _9105 = param_3.anisotropy;\n    _9106 = param_3.anisotropy_rotation;\n    _9107 = param_3.specular;\n    _9108 = param_3.ior;\n    _9109 = param_3.specular_color;\n    _9110 = param_3.transmission;\n    _9111 = param_3.thickness;\n    _9112 = param_3.attenuation_color;\n    _9113 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9063;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9094 = param_6;\n    _9096 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_650_fa_emissive.w > 0.5f)\n    {\n        result = _9094;\n    }\n    else\n    {\n        float3 _8404 = normalize(_9096);\n        float _8411 = clamp(_9097, 0.0f, 1.0f);\n        float _8415 = clamp(_9098, 0.0500000007450580596923828125f, 1.0f);\n        float _8419 = _8415 * _8415;\n        float _8423 = _8419 * _8419;\n        float _8428 = max(dot(_8404, _8356), 9.9999997473787516355514526367188e-05f);\n        float _8434 = 1.0f - _8411;\n        float _8435 = clamp(_9110, 0.0f, 1.0f) * _8434;\n        float3 _8444 = (_9094 * _8434) * (1.0f - _8435);\n        float3 _8451 = lerp(0.039999999105930328369140625f.xxx, _9094, _8411.xxx);\n        float3 f0 = _8451;\n        SurfaceInput _9092 = { fa_world_pos, _9063, fa_world_tangent, fa_uv, fa_vertex_color, _8356, gl_FrontFacing };\n        SurfaceInput param_8 = _9092;\n        Surface _9195 = { _9094, _9095, _9096, _9097, _9098, _9099, _9100, _9101, _9102, _9103, _9104, _9105, _9106, _9107, _9108, _9109, _9110, _9111, _9112, _9113 };\n        Surface param_9 = _9195;\n        float3 param_10 = _8404;\n        float3 param_11 = _8356;\n        float param_12 = _8411;\n        float param_13 = _8415;\n        float3 param_14 = _8451;\n        FaLayers _8467 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8404;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8444) * _9099;\n        if (_8467.on)\n        {\n            lit *= _8467.base_scale;\n        }\n        int _8489 = fa_cl_ndir + fa_cl_local;\n        float _8554;\n        for (int ln = 0; ln < _8489; ln++)\n        {\n            int param_16 = ln;\n            int _8502 = fa_cl_light(param_16);\n            int param_17 = _8502;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8502;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9063;\n            LightSample _8518 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8526 = max(dot(_8404, _8518.direction), 0.0f);\n            float _8532 = _8518.attenuation * _8518.shadow;\n            float3 _8537 = normalize(_8518.direction + _8356);\n            float _8542 = max(dot(_8404, _8537), 0.0f);\n            float _8547 = max(dot(_8356, _8537), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8467.on)\n                {\n                    _8554 = _8467.f90;\n                }\n                else\n                {\n                    _8554 = 1.0f;\n                }\n                int param_21 = _8502;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8404;\n                float3 param_24 = _8356;\n                float3 param_25 = _8444;\n                float3 param_26 = f0;\n                float param_27 = _8554;\n                float param_28 = _8415;\n                float param_29 = _8428;\n                float param_30 = _8532;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8467.on)\n                {\n                    FaLayers param_31 = _8467;\n                    float3 param_32 = area;\n                    int param_33 = _8502;\n                    float3 param_34 = _8404;\n                    float3 param_35 = _8356;\n                    float3 param_36 = _8518.direction;\n                    float param_37 = _8428;\n                    float param_38 = _8532;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8467.on)\n                {\n                    FaLayers param_39 = _8467;\n                    float3 param_40 = _8444;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8404;\n                    float3 param_43 = _8356;\n                    float3 param_44 = _8518.direction;\n                    float3 param_45 = _8537;\n                    float param_46 = _8526;\n                    float param_47 = _8428;\n                    float param_48 = _8542;\n                    float param_49 = _8547;\n                    float param_50 = _8419;\n                    float param_51 = _8423;\n                    int param_52 = _8502;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8532));\n                }\n                else\n                {\n                    float _8656 = ((_8542 * _8542) * (_8423 - 1.0f)) + 1.0f;\n                    int param_53 = _8502;\n                    lit += (((_8444 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8547, 5.0f))) * (((_8423 / ((3.1415927410125732421875f * _8656) * _8656)) * (0.5f / max(lerp((2.0f * _8526) * _8428, _8526 + _8428, _8419), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8526))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8526 * _8532));\n                }\n            }\n        }\n        if (_8467.on)\n        {\n            FaLayers param_54 = _8467;\n            float3 param_55 = _8404;\n            float3 param_56 = _8356;\n            float3 param_57 = f0;\n            float param_58 = _8415;\n            float param_59 = _9099;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8404;\n            float3 param_61 = _8356;\n            float3 param_62 = f0;\n            float param_63 = _8415;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9099);\n        }\n        if (_8435 > 0.0f)\n        {\n            float _8754;\n            if (_8467.on)\n            {\n                _8754 = _8467.f90;\n            }\n            else\n            {\n                _8754 = 1.0f;\n            }\n            float _8762;\n            if (_8467.on)\n            {\n                _8762 = _8467.base_scale;\n            }\n            else\n            {\n                _8762 = 1.0f;\n            }\n            Surface _9216 = { _9094, _9095, _9096, _9097, _9098, _9099, _9100, _9101, _9102, _9103, _9104, _9105, _9106, _9107, _9108, _9109, _9110, _9111, _9112, _9113 };\n            Surface param_64 = _9216;\n            float3 param_65 = _8404;\n            float3 param_66 = _8356;\n            float param_67 = _8415;\n            float3 param_68 = f0;\n            float param_69 = _8754;\n            float param_70 = _8762;\n            float param_71 = _8435;\n            float param_72 = fa_tr_blend;\n            float3 _8786 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8786;\n        }\n        result = lit;\n    }\n    float3 _8793 = result;\n    float3 _8794 = _8793 + _9100;\n    result = _8794;\n    float3 param_73 = _8794;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8803 = _650_fa_fog.w > 0.0f;\n    bool _8810;\n    if (!_8803)\n    {\n        _8810 = _650_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8810 = _8803;\n    }\n    if (_8810)\n    {\n        float3 _8819 = fa_world_pos - _650_fa_camera_pos.xyz;\n        float _8825 = dot(_8819, _650_fa_fog_c.xyz);\n        bool _8829 = _650_fa_fog_c.w > 0.5f;\n        float _8830;\n        if (_8829)\n        {\n            _8830 = _8825;\n        }\n        else\n        {\n            _8830 = length(_8819);\n        }\n        float _8842 = _8830 - _650_fa_fog_b.x;\n        if (_8842 > 0.0f)\n        {\n            float _8851 = _650_fa_fog.w * _8842;\n            float tau = _8851 * _8851;\n            if (_650_fa_fog_b.y > 0.0f)\n            {\n                float _8867;\n                if (_8829)\n                {\n                    _8867 = fa_world_pos.y - (_650_fa_fog_c.y * _8825);\n                }\n                else\n                {\n                    _8867 = _650_fa_camera_pos.y;\n                }\n                float _8888 = lerp(_8867, fa_world_pos.y, clamp(_650_fa_fog_b.x / _8830, 0.0f, 1.0f));\n                float _8892 = fa_world_pos.y - _8888;\n                float _8897 = _8888 - _650_fa_fog_b.z;\n                float _8902 = fa_world_pos.y - _650_fa_fog_b.z;\n                bool _8905 = _8897 <= 0.0f;\n                bool _8906 = !_8905;\n                bool _8912;\n                if (_8906)\n                {\n                    _8912 = _650_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8912 = _8905;\n                }\n                float _8913;\n                if (_8912)\n                {\n                    _8913 = _650_fa_fog_b.y;\n                }\n                else\n                {\n                    _8913 = _650_fa_fog_b.y * exp(-min(_650_fa_fog_b.w * _8897, 80.0f));\n                }\n                bool _8940;\n                if (_8906)\n                {\n                    _8940 = _650_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8940 = _8905;\n                }\n                float _8941;\n                if (_8940)\n                {\n                    _8941 = _650_fa_fog_b.y * _8897;\n                }\n                else\n                {\n                    _8941 = (_650_fa_fog_b.y * (1.0f - exp(-min(_650_fa_fog_b.w * _8897, 80.0f)))) / _650_fa_fog_b.w;\n                }\n                bool _8966 = _8902 <= 0.0f;\n                bool _8973;\n                if (!_8966)\n                {\n                    _8973 = _650_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8973 = _8966;\n                }\n                float _8974;\n                if (_8973)\n                {\n                    _8974 = _650_fa_fog_b.y * _8902;\n                }\n                else\n                {\n                    _8974 = (_650_fa_fog_b.y * (1.0f - exp(-min(_650_fa_fog_b.w * _8902, 80.0f)))) / _650_fa_fog_b.w;\n                }\n                float _9001;\n                if (abs(_8892) < 0.001000000047497451305389404296875f)\n                {\n                    _9001 = _8913;\n                }\n                else\n                {\n                    _9001 = (_8974 - _8941) / _8892;\n                }\n                tau += (_8842 * max(_9001, 0.0f));\n            }\n            result = lerp(result, _650_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9037 = 1.0f - fa_tr_blend;\n        result /= _9037.xxx;\n        _9095 *= _9037;\n    }\n    fa_frag_color = float4(result, _9095);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_650",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2312",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _187_fa_view_proj : packoffset(c0);\n    row_major float4x4 _187_fa_light_vp : packoffset(c4);\n    float4 _187_fa_uv_scale : packoffset(c8);\n    float4 _187_fa_time : packoffset(c9);\n    float4 _187_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _231_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _364_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_231_fa_joint_rows[_222] * weights[i]);\n        r1 += (_231_fa_joint_rows[_222 + 1] * weights[i]);\n        r2 += (_231_fa_joint_rows[_222 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * _187_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _82;\n    if (!_67)\n    {\n        _82 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _187_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _364_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstatic const float _4525[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _650_fa_camera_pos : packoffset(c0);\n    float4 _650_fa_ambient : packoffset(c1);\n    float4 _650_fa_base_color : packoffset(c2);\n    float4 _650_fa_emissive : packoffset(c3);\n    float4 _650_fa_model_emissive : packoffset(c4);\n    float4 _650_fa_pbr : packoffset(c5);\n    float4 _650_fa_maps : packoffset(c6);\n    float4 _650_fa_fog : packoffset(c7);\n    float4 _650_fa_fog_b : packoffset(c8);\n    float4 _650_fa_fog_c : packoffset(c9);\n    float4 _650_fa_counts : packoffset(c10);\n    float4 _650_fa_env_sky : packoffset(c11);\n    float4 _650_fa_env_horizon : packoffset(c12);\n    float4 _650_fa_time : packoffset(c13);\n    float4 _650_fa_cl_vpx : packoffset(c14);\n    float4 _650_fa_cl_vpy : packoffset(c15);\n    float4 _650_fa_cl_vpw : packoffset(c16);\n    float4 _650_fa_cl_fwd : packoffset(c17);\n    float4 _650_fa_cl_grid : packoffset(c18);\n    float4 _650_fa_cl_info : packoffset(c19);\n    float4 _650_fa_layers_a : packoffset(c20);\n    float4 _650_fa_layers_b : packoffset(c21);\n    float4 _650_fa_layers_c : packoffset(c22);\n    float4 _650_fa_layers_d : packoffset(c23);\n    float4 _650_fa_ct_a : packoffset(c24);\n    float4 _650_fa_ct_b : packoffset(c25);\n    float4 _650_fa_ct_vpx : packoffset(c26);\n    float4 _650_fa_ct_vpy : packoffset(c27);\n    float4 _650_fa_ct_vpw : packoffset(c28);\n    float4 _650_fa_ct_fwd : packoffset(c29);\n    float4 _650_fa_tr_a : packoffset(c30);\n    float4 _650_fa_tr_b : packoffset(c31);\n    float4 _650_fa_probe_sh[9] : packoffset(c32);\n    float4 _650_fa_atlas : packoffset(c41);\n    float4 _650_fa_rpa_tile : packoffset(c42);\n    float4 _650_fa_rpa_pos : packoffset(c43);\n    float4 _650_fa_rpa_bx : packoffset(c44);\n    float4 _650_fa_rpa_by : packoffset(c45);\n    float4 _650_fa_rpa_bz : packoffset(c46);\n    float4 _650_fa_rpb_tile : packoffset(c47);\n    float4 _650_fa_rpb_pos : packoffset(c48);\n    float4 _650_fa_rpb_bx : packoffset(c49);\n    float4 _650_fa_rpb_by : packoffset(c50);\n    float4 _650_fa_rpb_bz : packoffset(c51);\n    float4 _650_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2312_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2312_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2312_fa_shadow_info[4] : packoffset(c20);\n    float4 _2312_fa_shadow_split : packoffset(c24);\n    float4 _2312_fa_shadow_cfg : packoffset(c25);\n    float4 _2312_fa_shadow_bias : packoffset(c26);\n    float4 _2312_fa_shadow_eye : packoffset(c27);\n    float4 _2312_fa_shadow_fwd : packoffset(c28);\n    float4 _2312_fa_shadow_lcfg : packoffset(c29);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1588 = _650_fa_cl_info.x < 0.0f;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = _650_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    bool _1603;\n    if (!_1595)\n    {\n        _1603 = _650_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1603 = _1595;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = _650_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = _650_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1627 = float4(world_pos, 1.0f);\n    float _1633 = dot(_650_fa_cl_vpw, _1627);\n    if (!(_1633 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1655 = float2(dot(_650_fa_cl_vpx, _1627), dot(_650_fa_cl_vpy, _1627)) / _1633.xx;\n    int _1659 = int(_650_fa_cl_grid.x);\n    int _1663 = int(_650_fa_cl_grid.y);\n    int param = (int(_650_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_650_fa_cl_fwd.xyz, world_pos) + _650_fa_cl_fwd.w, _650_fa_cl_grid.w) / _650_fa_cl_grid.w) * _650_fa_cl_grid.z)), 0, int(_650_fa_cl_info.y) - 1) * _1663) + clamp(int(floor(((_1655.y * 0.5f) + 0.5f) * _650_fa_cl_grid.y)), 0, _1663 - 1)) * _1659)) + clamp(int(floor(((_1655.x * 0.5f) + 0.5f) * _650_fa_cl_grid.x)), 0, _1659 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1739 = fa_cluster_texel(param);\n    return int2(int(_1739.x), int(_1739.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_650_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _6159 = fa_cluster_lookup(param);\n    fa_cl_slot = _6159.x;\n    fa_cl_local = _6159.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _7333 = fa_linear_to_srgb(param);\n        c = _7333;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _7341 = fa_srgb_to_linear(param_1);\n            c = _7341;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _532;\n    if (i.front_facing)\n    {\n        _532 = i.world_normal;\n    }\n    else\n    {\n        _532 = -i.world_normal;\n    }\n    float3 _556 = normalize(i.world_tangent.xyz - (_532 * dot(_532, i.world_tangent.xyz)));\n    float3 _583 = normalize(((_556 * m.x) + ((cross(_532, _556) * i.world_tangent.w) * m.y)) + (_532 * m.z));\n    float3 _586;\n    if (i.front_facing)\n    {\n        _586 = _583;\n    }\n    else\n    {\n        _586 = -_583;\n    }\n    return _586;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w);\n    float param = _650_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _7373 = fa_tex_fix(param_2, param_3);\n    float4 _9664 = base_t;\n    _9664.x = _7373.x;\n    _9664.y = _7373.y;\n    _9664.z = _7373.z;\n    base_t = _9664;\n    float4 _7387 = (_9664 * _650_fa_base_color) * i.vertex_color;\n    float3 _9424 = i.world_normal;\n    if (_650_fa_maps.z > 0.5f)\n    {\n        float param_4 = _650_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _7421 = fa_tex_fix(param_6, param_7);\n        float3 _7424 = (_7421 * 2.0f) - 1.0f.xxx;\n        float2 _7429 = _7424.xy * _650_fa_maps.x;\n        float3 _9672 = _7424;\n        _9672.x = _7429.x;\n        _9672.y = _7429.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _9672;\n        _9424 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w);\n    float param_10 = _650_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _7459 = fa_tex_fix(param_12, param_13);\n    float4 _9675 = mrt;\n    _9675.x = _7459.x;\n    _9675.y = _7459.y;\n    _9675.z = _7459.z;\n    mrt = _9675;\n    float4 _7489 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w);\n    float param_14 = _650_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _7489.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _7500 = fa_tex_fix(param_16, param_17);\n    float param_18 = _650_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _650_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _7532 = fa_tex_fix(param_20, param_21);\n    float _9429 = _650_fa_layers_a.x;\n    float _9430 = _650_fa_layers_a.y;\n    float _9433 = _650_fa_layers_a.z;\n    float _9432 = _650_fa_layers_b.w;\n    float _9435 = _650_fa_layers_c.x;\n    if (_650_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_650_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _9429 *= _7500.y;\n            _9430 *= _7500.z;\n            _9432 *= _7489.w;\n        }\n        if (_650_fa_layers_c.z > 1.5f)\n        {\n            _9433 *= mrt.x;\n            _9435 *= mrt.w;\n        }\n    }\n    Surface _9462 = { _7387.xyz, _7387.w, _9424, clamp(_650_fa_pbr.x * _7459.z, 0.0f, 1.0f), clamp(_650_fa_pbr.y * _7459.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_650_fa_maps.y * (_7500.x - 1.0f)), _650_fa_emissive.xyz + (_650_fa_model_emissive.xyz * _7532), _9429, _9430, _650_fa_layers_b.xyz, _9432, _9433, _650_fa_layers_a.w, _9435, _650_fa_layers_c.y, _650_fa_layers_d.xyz, _650_fa_tr_a.x, _650_fa_tr_a.y, _650_fa_tr_b.xyz, _650_fa_tr_a.z };\n    return _9462;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1819 = rect.zw - rect.xy;\n    float2 _1823 = _1819 * atlas;\n    float2 _1827 = ddx * _1823;\n    float2 _1831 = ddy * _1823;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1819), clamp(0.5f * log2(max(max(dot(_1827, _1827), dot(_1831, _1831)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1864 = _650_fa_counts.y < 0.5f;\n    bool _1871;\n    if (!_1864)\n    {\n        _1871 = _650_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1871 = _1864;\n    }\n    if (_1871)\n    {\n        return;\n    }\n    float3 _1877 = ddx(world_pos);\n    float3 _1880 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1884 = fa_cluster_texel(param);\n    int _1888 = int(_1884.w);\n    if (_1888 < 1)\n    {\n        return;\n    }\n    int _1898 = int(_650_fa_counts.y + 0.5f);\n    int param_1 = _1898;\n    float4 _1902 = fa_light_texel(param_1);\n    float2 _1905 = _1902.yz;\n    int _1909 = int(_1902.w);\n    int param_2 = _1898 + 1;\n    float4 _1914 = fa_light_texel(param_2);\n    float _1915 = _1914.x;\n    int _1921 = int(_650_fa_counts.w + 0.5f) - 1;\n    int _1925 = int(_1884.z);\n    float3 _2190;\n    for (int k = 0; k < _1888; k++)\n    {\n        int _1938 = _1925 + k;\n        int param_3 = _1909 + (_1938 >> 2);\n        int _1955 = (_1898 + 2) + (int(fa_light_texel(param_3)[_1938 & 3]) * 7);\n        int param_4 = _1955 + 6;\n        float4 _1960 = fa_light_texel(param_4);\n        if (((int(_1960.w + 0.5f) >> _1921) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1955;\n        float4 _1975 = fa_light_texel(param_5);\n        int param_6 = _1955 + 1;\n        float4 _1980 = fa_light_texel(param_6);\n        int param_7 = _1955 + 2;\n        float4 _1985 = fa_light_texel(param_7);\n        float3 _1988 = _1975.xyz;\n        float _1993 = dot(_1988, world_pos) + _1975.w;\n        float3 _1995 = _1980.xyz;\n        float _2000 = dot(_1995, world_pos) + _1980.w;\n        float3 _2002 = _1985.xyz;\n        float _2007 = dot(_2002, world_pos) + _1985.w;\n        bool _2012 = abs(_1993) > 0.5f;\n        bool _2020;\n        if (!_2012)\n        {\n            _2020 = abs(_2000) > 0.5f;\n        }\n        else\n        {\n            _2020 = _2012;\n        }\n        bool _2028;\n        if (!_2020)\n        {\n            _2028 = abs(_2007) > 0.5f;\n        }\n        else\n        {\n            _2028 = _2020;\n        }\n        if (_2028)\n        {\n            continue;\n        }\n        float _2043 = clamp(dot(geo_normal, normalize(_2002)) * _1960.z, 0.0f, 1.0f);\n        if (_2043 <= 0.0f)\n        {\n            continue;\n        }\n        float _2063 = (clamp((0.5f - abs(_2007)) * 10.0f, 0.0f, 1.0f) * _2043) * _1960.x;\n        float2 _2071 = float2(_1993 + 0.5f, 0.5f - _2000);\n        float2 _2081 = float2(dot(_1988, _1877), dot(_1995, _1877));\n        float2 _2091 = float2(dot(_1988, _1880), dot(_1995, _1880));\n        int param_8 = _1955 + 5;\n        float4 _2096 = fa_light_texel(param_8);\n        int param_9 = _1955 + 3;\n        float4 _2101 = fa_light_texel(param_9);\n        int param_10 = _1955 + 4;\n        float4 _2106 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2096.xyz;\n        bool _2116 = _2101.z > _2101.x;\n        if (_2116)\n        {\n            float4 param_11 = _2101;\n            float2 param_12 = _2071;\n            float2 param_13 = _1905;\n            float2 param_14 = _2081;\n            float2 param_15 = _2091;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1915 > 0.5f) && (_1915 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2142 = fa_dc_to_linear(param_16);\n                float4 _9512 = tx;\n                _9512.x = _2142.x;\n                _9512.y = _2142.y;\n                _9512.z = _2142.z;\n                tx = _9512;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_2063 * tex_a) * _2096.w, 0.0f, 1.0f).xxx);\n        if (_2106.z > _2106.x)\n        {\n            float4 param_17 = _2106;\n            float2 param_18 = _2071;\n            float2 param_19 = _1905;\n            float2 param_20 = _2081;\n            float2 param_21 = _2091;\n            float4 _2186 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1915 > 1.5f)\n            {\n                float3 param_22 = _2186.xyz;\n                float3 _2196 = fa_dc_to_srgb(param_22);\n                _2190 = _2196;\n            }\n            else\n            {\n                _2190 = _2186.xyz;\n            }\n            float3 _2205 = (_2190 * 2.0f) - 1.0f.xxx;\n            float2 _2210 = _2205.xy * _1960.y;\n            float3 _2232 = (normalize(_1988) * _2210.x) + (normalize(_1995) * _2210.y);\n            float3 _2235 = normalize(normal);\n            normal = normalize(lerp(_2235, normalize((_2235 * max(_2205.z, 0.0500000007450580596923828125f)) + (_2232 - (_2235 * dot(_2235, _2232)))), clamp(_2063 * (_2116 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4450 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _4458 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _4461 = int(_4450);\n    int _4464 = int(_4458);\n    float _4474 = _4458 - float(_4464);\n    int _4529 = (_4461 * 9) + _4464;\n    int _4549 = ((_4461 + 1) * 9) + _4464;\n    return lerp(lerp(_4525[_4529], _4525[_4529 + 1], _4474), lerp(_4525[_4549], _4525[_4549 + 1], _4474), _4450 - float(_4461));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _9347 = false;\n    float _9348 = 1.0f;\n    float _9349 = 1.0f;\n    float _9350 = 1.0f;\n    float _9351 = 0.0f;\n    float _9352 = 0.0f;\n    float _9353 = 0.0f;\n    float _9354 = 0.0f;\n    float _9356 = 1.0f;\n    bool _9357 = false;\n    float3 _9358 = 0.0f.xxx;\n    float _9359 = 1.0f;\n    float _9360 = 1.0f;\n    float _9361 = 1.0f;\n    float _9362 = 0.0f;\n    float _9363 = 0.0f;\n    float3 _9364 = float3(1.0f, 0.0f, 0.0f);\n    float3 _9365 = float3(0.0f, 0.0f, 1.0f);\n    float _9366 = 1.0f;\n    float _9367 = 1.0f;\n    float _4600 = clamp(s.specular, 0.0f, 1.0f);\n    float _4604 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4609 = (_4600 != 1.0f) || (_4604 != 1.5f);\n    bool _4618;\n    if (!_4609)\n    {\n        _4618 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4618 = _4609;\n    }\n    if (_4618)\n    {\n        float _4626 = (_4604 - 1.0f) / (_4604 + 1.0f);\n        f0 = lerp(min((_4626 * _4626).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4600, s.albedo, metallic.xxx);\n        _9348 = lerp(_4600, 1.0f, metallic);\n        _9347 = true;\n    }\n    float _4653 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4653 > 0.0f)\n    {\n        float _4661 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _9351 = _4653;\n        _9352 = _4661;\n        float _4668 = _4661 * _4661;\n        _9353 = _4668;\n        _9354 = _4668 * _4668;\n        float _4680 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _9356 = _4680;\n        _9349 = 1.0f - (_4653 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4680, 0.0f, 1.0f), 5.0f))));\n        _9347 = true;\n    }\n    float3 _4699 = max(s.sheen_color, 0.0f.xxx);\n    float _4708 = max(_4699.x, max(_4699.y, _4699.z));\n    if (_4708 > 0.0f)\n    {\n        float _4716 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _9357 = true;\n        _9358 = _4699;\n        _9359 = _4716;\n        _9360 = _4716 * _4716;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4716;\n        float _4733 = fa_sheen_albedo(param, param_1);\n        _9362 = _4733;\n        _9361 = 1.0f - min(_4708 * _4733, 1.0f);\n        _9347 = true;\n    }\n    _9350 = _9349 * _9361;\n    float _4752 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4752 != 0.0f)\n    {\n        float3 _4767 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4767;\n        if (dot(_4767, _4767) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4779 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4779.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4779.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4779.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4783 = t;\n        float3 _4784 = normalize(_4783);\n        t = _4784;\n        float3 _4809 = normalize((_4784 * cos(s.anisotropy_rotation)) + ((cross(n, _4784) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _9364 = _4809;\n        _9365 = cross(n, _4809);\n        float _4819 = roughness * roughness;\n        float _4825 = lerp(_4819, 1.0f, _4752 * _4752);\n        bool _4827 = _4752 > 0.0f;\n        _9366 = _4827 ? _4825 : _4819;\n        _9367 = _4827 ? _4819 : _4825;\n        _9363 = _4752;\n        _9347 = true;\n    }\n    FaLayers _9389 = { _9347, _9348, _9349, _9350, _9351, _9352, _9353, _9354, i.world_normal, _9356, _9357, _9358, _9359, _9360, _9361, _9362, _9363, _9364, _9365, _9366, _9367 };\n    return _9389;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3678_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3678_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_650_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3619 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3619;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _4231 = (1.0f - _650_fa_rpa_tile.w) - _650_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _4236 = _650_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_4231 > 0.0005000000237487256526947021484375f)\n    {\n        if (_4236)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _650_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4231;\n            }\n        }\n        else\n        {\n            amb = _650_fa_ambient.xyz * _4231;\n        }\n    }\n    bool _4287 = _650_fa_rpa_tile.w > 0.0f;\n    if (_4287)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _650_fa_rpa_tile.xy;\n            float param_4 = _650_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _650_fa_rpa_tile.w);\n        }\n    }\n    bool _4318 = _650_fa_rpb_tile.w > 0.0f;\n    if (_4318)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _650_fa_rpb_tile.xy;\n            float param_7 = _650_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _650_fa_rpb_tile.w);\n        }\n    }\n    if ((_4236 || _4287) || _4318)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3639 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3642 = _3639.x;\n    float _3644 = _3639.z;\n    float2 e = float2(_3642, _3644);\n    if (_3639.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3644)) * ((_3642 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3642)) * ((_3644 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _7642 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _7647 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _7652 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _7657 = fa_light_texel(param_3);\n    bool _7660 = _7657.z < 0.5f;\n    bool _7668;\n    if (!_7660)\n    {\n        _7668 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _7668 = _7660;\n    }\n    if (_7668)\n    {\n        return 0.0f.xxx;\n    }\n    float _7675 = max(_7642.w, 9.9999997473787516355514526367188e-05f);\n    float3 _7678 = _7647.xyz;\n    float3 _7682 = _7642.xyz;\n    float3 _7686 = (fa_world_pos - _7682) / _7675.xxx;\n    float3 _7695 = min(_7686 + 0.5f.xxx, (_7678 - 0.5f.xxx) - _7686);\n    float _7704 = min(_7695.x, min(_7695.y, _7695.z));\n    if (!(_7704 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _7719 = _7678 - 1.0f.xxx;\n    float3 _7720 = clamp(_7686, 0.0f.xxx, _7719);\n    float3 _7728 = min(floor(_7720), max(_7678 - 2.0f.xxx, 0.0f.xxx));\n    float3 _7732 = _7720 - _7728;\n    float3 _7743 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _7675));\n    int _7748 = int(_7652.y + 0.5f);\n    float _7753 = 0.3257350027561187744140625f * n.y;\n    float _7757 = 0.3257350027561187744140625f * n.z;\n    float _7761 = 0.3257350027561187744140625f * n.x;\n    float _7768 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _7775 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _7784 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _7791 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _7804 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _7811 = 8 + int(_7657.w);\n    float _7838;\n    float _7851;\n    float _7865;\n    for (int k = 0; k < _7811; k++)\n    {\n        float _7824 = float(k & 1);\n        float _7828 = float((k >> 1) & 1);\n        float _7832 = float((k >> 2) & 1);\n        if (_7824 > 0.5f)\n        {\n            _7838 = _7732.x;\n        }\n        else\n        {\n            _7838 = 1.0f - _7732.x;\n        }\n        if (_7828 > 0.5f)\n        {\n            _7851 = _7732.y;\n        }\n        else\n        {\n            _7851 = 1.0f - _7732.y;\n        }\n        if (_7832 > 0.5f)\n        {\n            _7865 = _7732.z;\n        }\n        else\n        {\n            _7865 = 1.0f - _7732.z;\n        }\n        float _7875 = (_7838 * _7851) * _7865;\n        if (!(_7875 > 0.0f))\n        {\n            continue;\n        }\n        float3 _7888 = min(_7728 + float3(_7824, _7828, _7832), _7719);\n        int _7908 = int(((_7652.x + _7888.x) + (_7647.x * (_7888.y + (_7647.y * _7888.z)))) + 0.5f);\n        float2 _7923 = float2(float(_7908 % _7748) * 10.0f, 1024.0f + (float(_7908 / _7748) * 11.0f));\n        float2 param_4 = _7923 + float2(9.5f, 10.5f);\n        float4 _7931 = fa_gi_fetch(param_4);\n        bool _7934 = _7931.y < 0.5f;\n        bool _7943;\n        if (!_7934)\n        {\n            _7943 = _7931.x > _7657.y;\n        }\n        else\n        {\n            _7943 = _7934;\n        }\n        if (_7943)\n        {\n            continue;\n        }\n        float3 _7955 = _7743 - (_7682 + (_7888 * _7675));\n        float _7958 = length(_7955);\n        float3 _7964 = _7955 / max(_7958, 9.9999997473787516355514526367188e-05f).xxx;\n        float _7974 = max(9.9999997473787516355514526367188e-05f, (dot(-_7964, n) + 1.0f) * 0.5f);\n        float w = _7875 * (_7974 * _7974);\n        float3 param_5 = _7964;\n        float2 param_6 = (_7923 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _7993 = fa_gi_fetch(param_6);\n        float _8000 = _7958 / max(_7652.z, 9.9999997473787516355514526367188e-05f);\n        float _8003 = _7993.x;\n        if (_8000 > _8003)\n        {\n            float _8016 = max(_7993.y - (_8003 * _8003), 0.0f);\n            float _8021 = _8000 - _8003;\n            float _8030 = _8016 / max(_8016 + (_8021 * _8021), 9.9999999600419720025001879548654e-13f);\n            w *= ((_8030 * _8030) * _8030);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _7923 + float2(0.5f, 10.5f);\n        float2 param_8 = _7923 + float2(1.5f, 10.5f);\n        float2 param_9 = _7923 + float2(2.5f, 10.5f);\n        float2 param_10 = _7923 + float2(3.5f, 10.5f);\n        float2 param_11 = _7923 + float2(4.5f, 10.5f);\n        float2 param_12 = _7923 + float2(5.5f, 10.5f);\n        float2 param_13 = _7923 + float2(6.5f, 10.5f);\n        float2 param_14 = _7923 + float2(7.5f, 10.5f);\n        float2 param_15 = _7923 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _7753)) + (fa_gi_fetch(param_9).xyz * _7757)) + (fa_gi_fetch(param_10).xyz * _7761)) + (fa_gi_fetch(param_11).xyz * _7768)) + (fa_gi_fetch(param_12).xyz * _7775)) + (fa_gi_fetch(param_13).xyz * _7784)) + (fa_gi_fetch(param_14).xyz * _7791)) + (fa_gi_fetch(param_15).xyz * _7804)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_7704 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _8155;\n    if (_650_fa_gi.z > 0.5f)\n    {\n        _8155 = _7657.x;\n    }\n    else\n    {\n        _8155 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_7652.w * _8155);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _8179 = normalize(_650_fa_camera_pos.xyz - fa_world_pos);\n    int _8184 = int(_650_fa_gi.x + 0.5f);\n    int _8189 = int(_650_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _8189) && (k < 8); k++)\n    {\n        int param = _8184 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _8179;\n        float3 _8214 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8219 = param_3 * left;\n        acc += (_8214 * _8219);\n        left -= _8219;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_650_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _8248 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8248;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_650_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _650_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_650_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_650_fa_cl_info.x) + int(_650_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_650_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6129;\n    if (fa_lm.z > 0.5f)\n    {\n        _6129 = 0.0f;\n    }\n    else\n    {\n        _6129 = 1.0f - clamp(_650_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _6140 = _6129 < 1.0f;\n    bool _6146;\n    if (_6140)\n    {\n        int param = li;\n        _6146 = fa_light_baked(param);\n    }\n    else\n    {\n        _6146 = _6140;\n    }\n    return _6146 ? _6129 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _718_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _718_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _837 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _850 = (c - (ru * hx)) - p;\n        float3 _856 = ru * (2.0f * hx);\n        float _862 = max(dot(_856, _856), 9.9999999392252902907785028219223e-09f);\n        float _866 = dot(_850, _856);\n        float t = clamp((-_866) / _862, 0.0f, 1.0f);\n        if (_837)\n        {\n            float _881 = dot(r, _856);\n            float _887 = _862 - (_881 * _881);\n            if (abs(_887) > (9.9999997473787516355514526367188e-06f * _862))\n            {\n                t = clamp(((dot(r, _850) * _881) - _866) / _887, 0.0f, 1.0f);\n            }\n        }\n        return (p + _850) + (_856 * t);\n    }\n    float3 q = p;\n    float _919 = dot(r, axis);\n    bool _927;\n    if (_837)\n    {\n        _927 = abs(_919) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _927 = _837;\n    }\n    if (_927)\n    {\n        float _937 = dot(c - p, axis) / _919;\n        if (_937 > 0.0f)\n        {\n            q = p + (r * _937);\n        }\n    }\n    float3 _950 = q - c;\n    float2 xy = float2(dot(_950, ru), dot(_950, uu));\n    if (shape > 0.5f)\n    {\n        float _965 = length(xy);\n        if (_965 > hx)\n        {\n            xy *= (hx / _965);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _598 = abs(d);\n    float _600 = _598.x;\n    float _602 = _598.y;\n    bool _603 = _600 >= _602;\n    bool _611;\n    if (_603)\n    {\n        _611 = _600 >= _598.z;\n    }\n    else\n    {\n        _611 = _603;\n    }\n    int _612;\n    if (_611)\n    {\n        _612 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _627;\n        if (_602 >= _598.z)\n        {\n            _627 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _627 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _612 = _627;\n    }\n    return _612;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _757 = dot(d, right);\n    float _761 = dot(d, up);\n    float _772;\n    if (((_757 * _757) + (_761 * _761)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _772 = atan2(_761, _757) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _772 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_772 - floor(_772)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _1003 = fa_light_base(param);\n    bool _1007 = _650_fa_ambient.w > 4.5f;\n    int param_1 = _1003;\n    float4 _1011 = fa_light_texel(param_1);\n    int param_2 = _1003 + 1;\n    float4 _1016 = fa_light_texel(param_2);\n    float _1019 = _1016.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _1031 = _1007 && (_1019 > 2.5f);\n    fa_light_is_area = _1031;\n    bool _1033 = _1019 < 0.5f;\n    float3 l;\n    if (_1033)\n    {\n        l = normalize(_1011.xyz);\n        if (_1007)\n        {\n            int param_3 = _1003 + 6;\n            float4 _1047 = fa_light_texel(param_3);\n            if (_1047.z > 0.5f)\n            {\n                int param_4 = _1003 + 4;\n                float4 _1057 = fa_light_texel(param_4);\n                int param_5 = _1003 + 5;\n                float4 _1062 = fa_light_texel(param_5);\n                float2 param_6 = _1047.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _1057.xyz) * _1057.w, (-dot(world_pos, _1062.xyz)) * _1062.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1092 = _1011.xyz;\n        float3 _1094 = _1092 - world_pos;\n        float3 to_light = _1094;\n        float _1097 = length(_1094);\n        float reach = _1097;\n        bool front = true;\n        if (_1031)\n        {\n            int param_8 = _1003 + 7;\n            reach = max(_1097 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _1003 + 4;\n            float4 _1121 = fa_light_texel(param_9);\n            int param_10 = _1003 + 5;\n            float4 _1126 = fa_light_texel(param_10);\n            int param_11 = _1003 + 6;\n            float4 _1131 = fa_light_texel(param_11);\n            float _1132 = _1131.w;\n            int param_12 = _1003 + 2;\n            float3 _1139 = normalize(fa_light_texel(param_12).xyz);\n            bool _1141 = _1132 > 1.5f;\n            bool _1149;\n            if (!_1141)\n            {\n                _1149 = dot(_1139, to_light) < 0.0f;\n            }\n            else\n            {\n                _1149 = _1141;\n            }\n            front = _1149;\n            float3 r = 0.0f.xxx;\n            float3 _1158 = _650_fa_camera_pos.xyz - world_pos;\n            bool _1162 = dot(n, n) > 0.5f;\n            bool _1170;\n            if (_1162)\n            {\n                _1170 = dot(_1158, _1158) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1170 = _1162;\n            }\n            if (_1170)\n            {\n                r = reflect(-normalize(_1158), normalize(n));\n            }\n            float3 param_13 = _1092;\n            float3 param_14 = _1139;\n            float3 param_15 = _1121.xyz;\n            float3 param_16 = _1126.xyz;\n            float param_17 = _1121.w;\n            float param_18 = _1126.w;\n            float param_19 = _1132;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1206 = length(to_light);\n        dist = _1206;\n        l = to_light / max(_1206, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1220 = reach / max(_1011.w, 0.001000000047497451305389404296875f);\n        float _1226 = clamp(1.0f - (_1220 * _1220), 0.0f, 1.0f);\n        float _1228;\n        if (front)\n        {\n            _1228 = _1226 * _1226;\n        }\n        else\n        {\n            _1228 = 0.0f;\n        }\n        atten = _1228;\n        bool _1239 = _1019 < 2.5f;\n        if ((_1019 > 1.5f) && _1239)\n        {\n            int param_22 = _1003 + 2;\n            float4 _1247 = fa_light_texel(param_22);\n            float _1257 = _1247.w;\n            int param_23 = _1003 + 3;\n            float4 _1262 = fa_light_texel(param_23);\n            float _1263 = _1262.x;\n            float cos_inner = _1263;\n            if (_1263 > 1.5f)\n            {\n                cos_inner = lerp(_1257, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1257, cos_inner, dot(-l, normalize(_1247.xyz)));\n        }\n        if (_1007 && (_1019 < 1.5f))\n        {\n            int param_24 = _1003 + 6;\n            float4 _1287 = fa_light_texel(param_24);\n            if (_1287.z > 0.5f)\n            {\n                float3 _1295 = -to_light;\n                int param_25 = _1003 + 4;\n                int param_26 = _1003 + 5;\n                float3 _1309 = fa_light_texel(param_25).xyz;\n                float3 _1313 = fa_light_texel(param_26).xyz;\n                float3 _1322 = float3(dot(_1295, _1309), dot(_1295, _1313), dot(_1295, cross(_1309, _1313)));\n                float3 param_27 = _1322;\n                int _1326 = fa_cube_face(param_27);\n                int param_28 = _1326;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1353 = float2(dot(_1322, cross(param_29, param_30)), dot(_1322, param_30)) / max(dot(_1322, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1357 = _1326 / 3;\n                float2 param_31 = _1287.xy + (float2(float(_1326 - (_1357 * 3)), float(_1357)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1353.x), 0.5f - (0.5f * _1353.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1003 + 7;\n            float4 _1387 = fa_light_texel(param_33);\n            if (_1387.z > 0.5f)\n            {\n                int param_34 = _1003 + 2;\n                int param_35 = _1003 + 4;\n                int param_36 = _1003 + 5;\n                float2 param_37 = _1387.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1007 && _1239)\n            {\n                int param_42 = _1003 + 6;\n                float4 _1434 = fa_light_texel(param_42);\n                int param_43 = _1003 + 7;\n                float4 _1439 = fa_light_texel(param_43);\n                bool _1442 = _1434.z > 0.5f;\n                bool _1449;\n                if (!_1442)\n                {\n                    _1449 = _1439.z > 0.5f;\n                }\n                else\n                {\n                    _1449 = _1442;\n                }\n                if (_1449)\n                {\n                    int param_44 = _1003 + 2;\n                    float4 _1456 = fa_light_texel(param_44);\n                    float3 _1460 = normalize(_1456.xyz);\n                    int param_45 = _1003 + 4;\n                    float4 _1465 = fa_light_texel(param_45);\n                    int param_46 = _1003 + 5;\n                    float4 _1470 = fa_light_texel(param_46);\n                    if (_1442)\n                    {\n                        float3 _1478 = -to_light;\n                        float _1485 = _1456.w;\n                        float _1501 = 0.5f / max(dot(_1478, _1460) * (sqrt(max(1.0f - (_1485 * _1485), 0.0f)) / max(_1485, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1434.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1478, _1465.xyz) * _1501), 0.5f - (dot(_1478, _1470.xyz) * _1501));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1439.z > 0.5f)\n                    {\n                        float2 param_49 = _1439.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1460;\n                        float3 param_52 = _1465.xyz;\n                        float3 param_53 = _1470.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _9335 = _1016.xyz * atten;\n    if (_1007)\n    {\n        _9335 *= fa_light_tint;\n    }\n    int _1570;\n    if (_1033)\n    {\n        _1570 = 0;\n    }\n    else\n    {\n        _1570 = ((_1019 > 1.5f) && (_1019 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _9346 = { l, _9335, atten, 1.0f, dist, _1570 };\n    return _9346;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2302;\n    if (i == 0)\n    {\n        _2302 = _2312_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2318;\n        if (i == 1)\n        {\n            _2318 = _2312_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2326;\n            if (i == 2)\n            {\n                _2326 = _2312_fa_shadow_split.z;\n            }\n            else\n            {\n                _2326 = _2312_fa_shadow_split.w;\n            }\n            _2318 = _2326;\n        }\n        _2302 = _2318;\n    }\n    return _2302;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2359 = fa_shadow_depth(param, param_1);\n    float _2363;\n    if (conv.x < 0.5f)\n    {\n        _2363 = _2359;\n    }\n    else\n    {\n        _2363 = (conv.y * conv.z) / (conv.z - (_2359 * (conv.z - conv.y)));\n    }\n    return _2363;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2409 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2415 = float2(cos(_2409), sin(_2409));\n    float2 dir = _2415;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2424;\n        if (k < 0.0f)\n        {\n            _2424 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2424 = k;\n        }\n        float _2443 = clamp((_2424 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2462 = sqrt((float(i) + 0.5f) * 0.0625f) * _2443;\n            float2 param_3 = uv + (dir * (_2312_fa_shadow_bias.zw * _2462));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2476 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2476 < (zr - (_2462 * plane)))\n            {\n                sum += _2476;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0f)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0f) * unit) * _2514) / texel_m, 1.5f, 16.0f);\n        dir = _2415;\n    }\n    float lit = 0.0f;\n    int _2540 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2540; i_1++)\n    {\n        float _2559 = sqrt((float(i_1) + 0.5f) / float(_2540)) * radius;\n        float2 param_7 = uv + (dir * (_2312_fa_shadow_bias.zw * _2559));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2559 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2540);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2605 = max(_2312_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2610 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2616 = sqrt(1.0f - (_2610 * _2610));\n    float _2624 = min(_2616 / max(_2610, 0.20000000298023223876953125f), 4.0f);\n    float _2629;\n    if (_2312_fa_shadow_bias.y > 0.0f)\n    {\n        _2629 = _2312_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2629 = 1.5f * _2312_fa_shadow_info[ci].x;\n    }\n    float4 _2654 = mul(float4(world + (n * (_2629 * _2616)), 1.0f), _2312_fa_shadow_mat[ci]);\n    float _2661 = _2654.x;\n    bool _2664 = _2661 < _2312_fa_shadow_rect[ci].x;\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2661 > _2312_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2654.y < _2312_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2654.y > _2312_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2698;\n    if (!_2691)\n    {\n        _2698 = _2654.z > 1.0f;\n    }\n    else\n    {\n        _2698 = _2691;\n    }\n    if (_2698)\n    {\n        return -1.0f;\n    }\n    float _2706;\n    if (_2312_fa_shadow_bias.x > 0.0f)\n    {\n        _2706 = _2312_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2706 = 1.5f * _2312_fa_shadow_info[ci].x;\n    }\n    float2 param = _2654.xy;\n    float4 param_1 = _2312_fa_shadow_rect[ci];\n    float param_2 = _2654.z - ((_2706 * (1.0f + (0.5f * _2624))) / _2605);\n    float param_3 = _2312_fa_shadow_info[ci].x;\n    float param_4 = _2605;\n    float param_5 = _2605 * 0.25f;\n    float param_6 = ((_2312_fa_shadow_info[ci].x * min(_2624, 3.0f)) * 0.5f) / _2605;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2312_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2312_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_650_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _3084 = int(_2312_fa_shadow_cfg.x + 0.5f);\n    if (_3084 < 1)\n    {\n        return 1.0f;\n    }\n    float _3099 = dot(world - _2312_fa_shadow_eye.xyz, _2312_fa_shadow_fwd.xyz);\n    int param = _3084 - 1;\n    if (_3099 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3111 = _3084 > 1;\n    bool _3118;\n    if (_3111)\n    {\n        _3118 = _3099 > _2312_fa_shadow_split.x;\n    }\n    else\n    {\n        _3118 = _3111;\n    }\n    if (_3118)\n    {\n        ci = 1;\n    }\n    bool _3122 = _3084 > 2;\n    bool _3129;\n    if (_3122)\n    {\n        _3129 = _3099 > _2312_fa_shadow_split.y;\n    }\n    else\n    {\n        _3129 = _3122;\n    }\n    if (_3129)\n    {\n        ci = 2;\n    }\n    bool _3133 = _3084 > 3;\n    bool _3140;\n    if (_3133)\n    {\n        _3140 = _3099 > _2312_fa_shadow_split.z;\n    }\n    else\n    {\n        _3140 = _3133;\n    }\n    if (_3140)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _3151 = min(_3084, 4);\n    float _3192;\n    for (int c = ci; c < _3151; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3171;\n            break;\n        }\n        if (_3171 < 0.0f)\n        {\n            continue;\n        }\n        s = _3171;\n        ci = c;\n        if (_2312_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3192 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3192 = _2312_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3211 = _2312_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3192, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_3099 - (fa_shadow_split_at(param_7) - _3211)) / _3211, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3243;\n        if ((ci + 1) < _3084)\n        {\n            _3243 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3243 = 1.0f;\n        }\n        s = lerp(s, _3243, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3348 = _650_fa_ct_b.y > 0.5f;\n    bool _3354;\n    if (_3348)\n    {\n        _3354 = _650_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3354 = _3348;\n    }\n    if (_3354)\n    {\n        float _3368 = dot(_650_fa_ct_fwd.xyz, fa_world_pos) + _650_fa_ct_fwd.w;\n        float _3371 = fwidth(_3368);\n        float4 _3381 = float4(fa_world_pos, 1.0f);\n        float _3387 = dot(_650_fa_ct_vpw, _3381);\n        if (_3387 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3406 = float2(dot(_650_fa_ct_vpx, _3381), dot(_650_fa_ct_vpy, _3381)) / _3387.xx;\n            float _3411 = (_3406.x * 0.5f) + 0.5f;\n            float _3415;\n            if (_650_fa_ct_a.y > 0.5f)\n            {\n                _3415 = (_3406.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3415 = 0.5f - (_3406.y * 0.5f);\n            }\n            bool _3431 = _3411 >= 0.0f;\n            bool _3437;\n            if (_3431)\n            {\n                _3437 = _3411 < 1.0f;\n            }\n            else\n            {\n                _3437 = _3431;\n            }\n            bool _3443;\n            if (_3437)\n            {\n                _3443 = _3415 >= 0.0f;\n            }\n            else\n            {\n                _3443 = _3437;\n            }\n            bool _3449;\n            if (_3443)\n            {\n                _3449 = _3415 < 1.0f;\n            }\n            else\n            {\n                _3449 = _3443;\n            }\n            if (_3449)\n            {\n                float4 _3475 = fa_screen_tex.Load(int3(clamp(int2(float2(_3411, _3415) * _650_fa_ct_a.zw), int2(0, 0), int2(_650_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3478 = _3475.w > 0.5f;\n                bool _3494;\n                if (_3478)\n                {\n                    _3494 = abs(_3368 - _3475.x) <= (((0.00200000009499490261077880859375f * _3368) + 0.00999999977648258209228515625f) + min(1.5f * _3371, 0.100000001490116119384765625f * _3368));\n                }\n                else\n                {\n                    _3494 = _3478;\n                }\n                if (_3494)\n                {\n                    float _3500;\n                    if (_650_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3500 = min(_3475.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3500 = _3475.y;\n                    }\n                    return _3500;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2764 = _650_fa_pbr.z < 0.5f;\n    bool _2771;\n    if (!_2764)\n    {\n        _2771 = _2312_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2771 = _2764;\n    }\n    if (_2771)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2312_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2784 = fa_light_texel(param);\n    float _2785 = _2784.x;\n    if (_2785 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2794 = int(_2785 + 0.5f);\n    int param_1 = _2794;\n    float4 _2798 = fa_light_texel(param_1);\n    int param_2 = _2794 + 1;\n    float4 _2803 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2806 = _2798.y;\n    if (_2806 > 0.0f)\n    {\n        float _2823 = 1.0f - smoothstep(0.75f * _2806, _2806, length(world - _2312_fa_shadow_eye.xyz));\n        fade = _2823;\n        if (_2823 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2798.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2847 = (_2794 + 2) + (face * 6);\n    int param_4 = _2847;\n    int param_5 = _2847 + 1;\n    int param_6 = _2847 + 3;\n    float4 _2861 = fa_light_texel(param_6);\n    int param_7 = _2847 + 4;\n    float4 _2866 = fa_light_texel(param_7);\n    int param_8 = _2847 + 5;\n    float4 _2871 = fa_light_texel(param_8);\n    float _2883 = _2871.x * max(dot(_2861, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2888 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2911 = clamp(dot(n, _2861.xyz), -1.0f, 1.0f);\n    float _2930 = min(sqrt(1.0f - (_2911 * _2911)) / max(abs(dot(n, world - lpos)) / max(dot(_2861, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2933 = _2803.y;\n    float _2935;\n    if (_2933 > 0.0f)\n    {\n        _2935 = _2933;\n    }\n    else\n    {\n        _2935 = 1.5f * _2883;\n    }\n    float4 _2955 = float4(world + (n * (_2935 * sqrt(1.0f - (_2888 * _2888)))), 1.0f);\n    float _2959 = dot(_2861, _2955);\n    float _2962 = _2871.y;\n    if (_2959 < _2962)\n    {\n        return 1.0f;\n    }\n    float2 _2977 = float2(dot(fa_light_texel(param_4), _2955), dot(fa_light_texel(param_5), _2955)) / _2959.xx;\n    float _2979 = _2977.x;\n    bool _2982 = _2979 < _2866.x;\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2979 > _2866.z;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2977.y < _2866.y;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2977.y > _2866.w;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        return 1.0f;\n    }\n    float _3015 = _2803.x;\n    float _3017;\n    if (_3015 > 0.0f)\n    {\n        _3017 = _3015;\n    }\n    else\n    {\n        _3017 = 1.5f * _2883;\n    }\n    float2 param_9 = _2977;\n    float4 param_10 = _2866;\n    float param_11 = _2959 - (_3017 * (1.0f + (0.5f * _2930)));\n    float param_12 = _2883;\n    float param_13 = 1.0f;\n    float param_14 = _2871.z * 0.25f;\n    float param_15 = (_2883 * min(_2930, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2962, _2871.z);\n    int param_17 = int(_2798.z + 0.5f);\n    float param_18 = _2798.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _5343 = _650_fa_ct_a.x < 0.5f;\n    bool _5350;\n    if (!_5343)\n    {\n        _5350 = _2312_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _5350 = _5343;\n    }\n    if (_5350)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2312_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _5363 = fa_light_texel(param);\n    float _5364 = _5363.y;\n    float len = _5364;\n    if (_5364 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5376 = length(world - _650_fa_camera_pos.xyz);\n    float _5385 = 1.0f - smoothstep(0.5f * _650_fa_ct_b.x, _650_fa_ct_b.x, _5376);\n    if (_5385 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _5391 = len;\n    float _5394 = min(_5391, 0.89999997615814208984375f * dist);\n    len = _5394;\n    float _5399 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _5376);\n    float _5404 = _5399 + (0.5f * _5394);\n    float3 _5410 = world + (gn * _5399);\n    float _5412 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _5473;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5427 = (float(k) + _5412) * 0.083333335816860198974609375f;\n        float3 _5435 = _5410 + (l * (_5427 * len));\n        float4 _5441 = float4(_5435, 1.0f);\n        float _5446 = dot(_650_fa_ct_vpw, _5441);\n        if (_5446 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _5464 = float2(dot(_650_fa_ct_vpx, _5441), dot(_650_fa_ct_vpy, _5441)) / _5446.xx;\n        float _5468 = _5464.x * 0.5f;\n        float _5469 = _5468 + 0.5f;\n        if (_650_fa_ct_a.y > 0.5f)\n        {\n            _5473 = (_5464.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5473 = 0.5f - (_5464.y * 0.5f);\n        }\n        bool _5489 = _5469 < 0.0f;\n        bool _5496;\n        if (!_5489)\n        {\n            _5496 = _5469 >= 1.0f;\n        }\n        else\n        {\n            _5496 = _5489;\n        }\n        bool _5503;\n        if (!_5496)\n        {\n            _5503 = _5473 < 0.0f;\n        }\n        else\n        {\n            _5503 = _5496;\n        }\n        bool _5510;\n        if (!_5503)\n        {\n            _5510 = _5473 >= 1.0f;\n        }\n        else\n        {\n            _5510 = _5503;\n        }\n        if (_5510)\n        {\n            break;\n        }\n        float4 _5534 = fa_screen_tex.Load(int3(clamp(int2(float2(_5469, _5473) * _650_fa_ct_a.zw), int2(0, 0), int2(_650_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_5534.w < 0.5f)\n        {\n            continue;\n        }\n        float _5552 = (dot(_650_fa_ct_fwd.xyz, _5435) + _650_fa_ct_fwd.w) - _5534.x;\n        if ((_5552 > _5399) && (_5552 < _5404))\n        {\n            occ = max(occ, (1.0f - (_5427 * _5427)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_5469, 0.5f - _5468), min(_5473, 1.0f - _5473))));\n        }\n    }\n    return 1.0f - (occ * _5385);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _6185 = fa_baked_keep(param);\n    if (_6185 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _9402 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _9402;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _6211 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _9404 = _6211.color;\n    float _9405 = _6211.attenuation;\n    float _9406 = _6211.shadow;\n    bool _6214 = _6211.type == 0;\n    if (_6214 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _6211.direction;\n        float _6225 = fa_shadow_factor(param_5, param_6);\n        _9406 = _6225;\n        _9404 *= _6225;\n    }\n    else\n    {\n        bool _6236 = _6211.type != 0;\n        bool _6242;\n        if (_6236)\n        {\n            _6242 = _9405 > 0.0f;\n        }\n        else\n        {\n            _6242 = _6236;\n        }\n        if (_6242)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _6211.direction;\n            float _6261 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9406 = _6261;\n            _9404 *= _6261;\n        }\n    }\n    bool _6271 = _650_fa_ct_a.x > 0.5f;\n    bool _6277;\n    if (_6271)\n    {\n        _6277 = _9405 > 0.0f;\n    }\n    else\n    {\n        _6277 = _6271;\n    }\n    if (_6277)\n    {\n        float _6284;\n        if (_6214)\n        {\n            _6284 = 1000000000.0f;\n        }\n        else\n        {\n            _6284 = _6211._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _6211.direction;\n        float param_18 = _6284;\n        float _6302 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9406 *= _6302;\n        _9404 *= _6302;\n    }\n    float _6315 = _9405;\n    float _6316 = _6315 * _6185;\n    _9405 = _6316;\n    float3 _6320 = _9404;\n    float3 _6321 = _6320 * _6185;\n    _9404 = _6321;\n    LightSample _9421 = { _6211.direction, _6321, _6316, _9406, _6211._distance, _6211.type };\n    return _9421;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _6355 = v - (n * dot(v, n));\n    float3 t = _6355;\n    float _6359 = dot(_6355, _6355);\n    float l2 = _6359;\n    if (_6359 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _6369;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _6369 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _6369 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _6369;\n        l2 = dot(_6369, _6369);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_oct_vertex(int j, float3 pc, float3 ex, float3 ey)\n{\n    float _6756;\n    if ((j == 0) || (j == 7))\n    {\n        _6756 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6766;\n        if ((j == 3) || (j == 4))\n        {\n            _6766 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6766 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6756 = _6766;\n    }\n    float _6787;\n    if ((j == 1) || (j == 2))\n    {\n        _6787 = 0.92387950420379638671875f;\n    }\n    else\n    {\n        float _6796;\n        if ((j == 5) || (j == 6))\n        {\n            _6796 = -0.92387950420379638671875f;\n        }\n        else\n        {\n            _6796 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625f : (-0.3826834261417388916015625f);\n        }\n        _6787 = _6796;\n    }\n    return (pc + (ex * _6756)) + (ey * _6787);\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _6404 = dot(a, a);\n    float _6408 = dot(b, b);\n    if ((_6404 < 1.0000000195414813782625560981111e-24f) || (_6408 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _6422 = a * rsqrt(_6404);\n    float3 _6427 = b * rsqrt(_6408);\n    float _6431 = dot(_6422, _6427);\n    float _6434 = abs(_6431);\n    float g = (((((((((((0.0416471660137176513671875f * _6434) - 0.1924748718738555908203125f) * _6434) + 0.4179156124591827392578125f) * _6434) - 0.616057217121124267578125f) * _6434) + 0.777722418308258056640625f) * _6434) - 0.999542415142059326171875f) * _6434) + 1.570791721343994140625f;\n    if (_6431 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_6431 * _6431), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_6422, _6427) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _6491 = a.z > 0.0f;\n    bool _6495 = b.z > 0.0f;\n    if (_6491 && _6495)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6491 != _6495)\n        {\n            float3 _6530 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6530.z = 0.0f;\n            if (_6491)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _6530;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6530;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _6530;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6530;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _6579 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _6605 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _6631 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _6657 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _6579;\n    float3 param_1 = _6605;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _6605;\n    float3 param_7 = _6631;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _6631;\n    float3 param_13 = _6657;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _6657;\n    float3 param_19 = _6579;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat2 fa_area_forms(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    int _6825 = ((shape < 0.5f) || (shape > 1.5f)) ? 1 : 3;\n    float2 sum = 0.0f.xx;\n    int _6843;\n    for (int k = 0; k < (2 * _6825); k++)\n    {\n        bool _6840 = k >= _6825;\n        if (_6840)\n        {\n            _6843 = k - _6825;\n        }\n        else\n        {\n            _6843 = k;\n        }\n        float3 p0 = (pc - ex) - ey;\n        float3 p1 = (pc + ex) - ey;\n        float3 p2 = (pc + ex) + ey;\n        float3 p3 = (pc - ex) + ey;\n        if (_6825 == 3)\n        {\n            int param = 0;\n            float3 param_1 = pc;\n            float3 param_2 = ex;\n            float3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6889 = 2 * _6843;\n            int param_4 = _6889 + 1;\n            float3 param_5 = pc;\n            float3 param_6 = ex;\n            float3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6889 + 2;\n            float3 param_9 = pc;\n            float3 param_10 = ex;\n            float3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6889 + 3;\n            float3 param_13 = pc;\n            float3 param_14 = ex;\n            float3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bool4 _6926 = _6840.xxxx;\n        float4 param_16 = float4(_6926.x ? m.x : float4(1.0f, 0.0f, 0.0f, 1.0f).x, _6926.y ? m.y : float4(1.0f, 0.0f, 0.0f, 1.0f).y, _6926.z ? m.z : float4(1.0f, 0.0f, 0.0f, 1.0f).z, _6926.w ? m.w : float4(1.0f, 0.0f, 0.0f, 1.0f).w);\n        float3 param_17 = p0;\n        float3 param_18 = p1;\n        float3 param_19 = p2;\n        float3 param_20 = p3;\n        float _6937 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6840)\n        {\n            float2 _9647 = sum;\n            _9647.y = _9647.y + _6937;\n            sum = _9647;\n        }\n        else\n        {\n            float2 _9650 = sum;\n            _9650.x = _9650.x + _6937;\n            sum = _9650;\n        }\n    }\n    return abs(sum);\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6961 = fa_light_base(param);\n    int param_1 = _6961;\n    int param_2 = _6961 + 1;\n    int param_3 = _6961 + 2;\n    int param_4 = _6961 + 4;\n    float4 _6983 = fa_light_texel(param_4);\n    int param_5 = _6961 + 5;\n    float4 _6988 = fa_light_texel(param_5);\n    int param_6 = _6961 + 6;\n    float4 _6993 = fa_light_texel(param_6);\n    float _6994 = _6993.w;\n    float3 _6999 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7001 = _6994 < 1.5f;\n    bool _7008;\n    if (_7001)\n    {\n        _7008 = dot(normalize(fa_light_texel(param_3).xyz), _6999) >= 0.0f;\n    }\n    else\n    {\n        _7008 = _7001;\n    }\n    if (_7008)\n    {\n        return 0.0f.xxx;\n    }\n    bool _7017 = (_6994 > 0.5f) && _7001;\n    float _7021 = _7017 ? 1.0539000034332275390625f : 1.0f;\n    float3 _7024 = _6983.xyz;\n    float _7026 = _6983.w;\n    float3 _7032 = _6988.xyz;\n    float _7034 = _6988.w;\n    float3 up = _7032 * (_7034 * _7021);\n    float _7040;\n    if (_7017)\n    {\n        _7040 = (3.1415927410125732421875f * _7026) * _7026;\n    }\n    else\n    {\n        _7040 = (4.0f * _7026) * _7034;\n    }\n    if (_6994 > 1.5f)\n    {\n        float3 _7066 = cross(_7024, -_6999);\n        float3 perp = _7066;\n        float _7070 = dot(_7066, _7066);\n        float3 _7073;\n        if (_7070 > 1.0000000133514319600180897396058e-10f)\n        {\n            _7073 = perp * rsqrt(_7070);\n        }\n        else\n        {\n            _7073 = _7032;\n        }\n        perp = _7073;\n        up = _7073 * _7034;\n    }\n    float _7094 = max(_7040, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _7104 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _7104;\n    float3 param_10 = n;\n    float3 param_11 = _6999;\n    float3 param_12 = _7104;\n    float3 param_13 = n;\n    float3 param_14 = _7024 * (_7026 * _7021);\n    float3 param_15 = _7104;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    float2 _7135 = fa_ltc_uv(param_18, param_19) * 64.0f;\n    float2 param_20 = _7135;\n    float2 param_21 = _7135 + float2(64.0f, 0.0f);\n    float4 _7145 = fa_atlas_fetch(param_21);\n    float4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6994;\n    float3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    float2 _7157 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7157.x) + (((f0 * _7145.x) + ((f90.xxx - f0) * _7145.y)) * _7157.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_6999, _6999)) + _7094) / _7094) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5080 = 1.0f / alpha;\n    return ((2.0f + _5080) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _5080)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _5115 = max(dot(L.nc, l), 0.0f);\n    float _5121 = max(dot(L.nc, h), 0.0f);\n    float _5130 = ((_5121 * _5121) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _5130) * _5130)) * (0.5f / max(lerp((2.0f * _5115) * L.coat_ndv, _5115 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _5115)) * _5115;\n}\n\nfloat3 fa_area_layers(FaLayers L, float3 base, int li, float3 n, float3 v, float3 l, float ndv, float window)\n{\n    float _7194;\n    if (L.sheen_on)\n    {\n        _7194 = L.sheen_scale;\n    }\n    else\n    {\n        _7194 = 1.0f;\n    }\n    float3 result = base * (L.keep * _7194);\n    float3 _7207 = normalize(l + v);\n    int param = li;\n    float3 _7218 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7227 = max(dot(n, l), 0.0f);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7207), 0.0f);\n        float param_3 = _7227;\n        float param_4 = ndv;\n        result += ((L.sheen * _7218) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _7227)) * _7227) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_5 = L;\n        float3 param_6 = l;\n        float3 param_7 = _7207;\n        float param_8 = max(dot(v, _7207), 0.0f);\n        result += (_7218 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4983 = tdh / at;\n    float _4987 = bdh / ab;\n    float _4999 = ((_4983 * _4983) + (_4987 * _4987)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4999) * _4999);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5179 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5258 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _5258) * _5258);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _5179);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _5179));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _4382 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _4385 = _4382.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_4385 * _4385, exp2((-9.27999973297119140625f) * ndv)) * _4385) + _4382.y)) + _4382.zw;\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3691;\n    if (lv == 0)\n    {\n        _3691 = 0.0f;\n    }\n    else\n    {\n        _3691 = res + 2.0f;\n    }\n    float _3701;\n    if (lv == 0)\n    {\n        _3701 = 0.0f;\n    }\n    else\n    {\n        _3701 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3691, _3701)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3747;\n    if (res > 64.5f)\n    {\n        _3747 = 5.0f;\n    }\n    else\n    {\n        _3747 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3762 = clamp(rough, 0.0f, 1.0f) * (_3747 - 1.0f);\n    int _3769 = int(min(floor(_3762), _3747 - 2.0f));\n    float _3774 = _3762 - float(_3769);\n    float3 param = d;\n    float2 _3778 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3769;\n    float2 param_4 = _3778;\n    float3 _3788 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3774 < 0.00200000009499490261077880859375f)\n    {\n        return _3788;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3769 + 1;\n    float2 param_8 = _3778;\n    return lerp(_3788, fa_probe_level(param_5, param_6, param_7, param_8), _3774.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3860 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3867 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3874 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3880 = dot(bx.xyz, d);\n    float _3884 = dot(by.xyz, d);\n    float _3888 = dot(bz.xyz, d);\n    float _3894;\n    if (_3880 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3894 = (1.0f - _3860) / _3880;\n    }\n    else\n    {\n        float _3908;\n        if (_3880 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3908 = ((-1.0f) - _3860) / _3880;\n        }\n        else\n        {\n            _3908 = 1000000015047466219876688855040.0f;\n        }\n        _3894 = _3908;\n    }\n    float tx = _3894;\n    float _3925;\n    if (_3884 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3925 = (1.0f - _3867) / _3884;\n    }\n    else\n    {\n        float _3938;\n        if (_3884 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3938 = ((-1.0f) - _3867) / _3884;\n        }\n        else\n        {\n            _3938 = 1000000015047466219876688855040.0f;\n        }\n        _3925 = _3938;\n    }\n    float ty = _3925;\n    float _3954;\n    if (_3888 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3954 = (1.0f - _3874) / _3888;\n    }\n    else\n    {\n        float _3967;\n        if (_3888 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3967 = ((-1.0f) - _3874) / _3888;\n        }\n        else\n        {\n            _3967 = 1000000015047466219876688855040.0f;\n        }\n        _3954 = _3967;\n    }\n    float _3979 = tx;\n    float _3982 = (_3979 > 0.0f) ? _3979 : 1000000015047466219876688855040.0f;\n    tx = _3982;\n    float _3983 = ty;\n    float _3986 = (_3983 > 0.0f) ? _3983 : 1000000015047466219876688855040.0f;\n    ty = _3986;\n    float _3996 = min(_3982, min(_3986, (_3954 > 0.0f) ? _3954 : 1000000015047466219876688855040.0f));\n    if (_3996 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _4012 = (fa_world_pos + (d * _3996)) - posw.xyz;\n    float3 _4017;\n    if (dot(_4012, _4012) > 1.0000000133514319600180897396058e-10f)\n    {\n        _4017 = normalize(_4012);\n    }\n    else\n    {\n        _4017 = d;\n    }\n    return _4017;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _4063 = (1.0f - _650_fa_rpa_tile.w) - _650_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_4063 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_650_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _650_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4091 = rough * rough;\n            float _4122 = 0.60000002384185791015625f * _4091;\n            base = lerp(lerp(_650_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_650_fa_env_horizon.xyz, _650_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _4091)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _4122, 0.0500000007450580596923828125f + _4122, d.y).xxx), ((_650_fa_env_sky.xyz + _650_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_4091 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _4063;\n    }\n    if (_650_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _650_fa_rpa_tile;\n        float4 param_5 = _650_fa_rpa_pos;\n        float4 param_6 = _650_fa_rpa_bx;\n        float4 param_7 = _650_fa_rpa_by;\n        float4 param_8 = _650_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _4181 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4181 * _650_fa_rpa_tile.w);\n    }\n    if (_650_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _650_fa_rpb_tile;\n        float4 param_12 = _650_fa_rpb_pos;\n        float4 param_13 = _650_fa_rpb_bx;\n        float4 param_14 = _650_fa_rpb_by;\n        float4 param_15 = _650_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _4213 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4213 * _650_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4860;\n        if (L.aniso >= 0.0f)\n        {\n            _4860 = L.b;\n        }\n        else\n        {\n            _4860 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4860, v), _4860), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4896 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4896.x) + (L.f90.xxx * _4896.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4954 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4954.x) + _4954.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4424 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4424.x) + _4424.y.xxx);\n}\n\nfloat2 fa_xm_size(int k)\n{\n    return max(floor(_650_fa_ct_a.zw / float(1 << k).xx), 1.0f.xx);\n}\n\nfloat2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return 0.0f.xx;\n    }\n    float y = 0.0f;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return float2(_650_fa_ct_a.z, y);\n}\n\nfloat3 fa_xm_texel(float2 size, float2 origin, float2 p)\n{\n    return fa_screen_tex.Load(int3(int2(origin + clamp(p, 0.0f.xx, size - 1.0f.xx)), 0)).xyz;\n}\n\nfloat3 fa_xm_level(int k, float2 uv)\n{\n    int param = k;\n    float2 _5656 = fa_xm_size(param);\n    int param_1 = k;\n    float2 _5660 = fa_xm_origin(param_1);\n    float2 _5666 = (uv * _5656) - 0.5f.xx;\n    float2 _5669 = frac(_5666);\n    float2 _5672 = floor(_5666);\n    float2 param_2 = _5656;\n    float2 param_3 = _5660;\n    float2 param_4 = _5672;\n    float2 param_5 = _5656;\n    float2 param_6 = _5660;\n    float2 param_7 = _5672 + float2(1.0f, 0.0f);\n    float2 param_8 = _5656;\n    float2 param_9 = _5660;\n    float2 param_10 = _5672 + float2(0.0f, 1.0f);\n    float2 param_11 = _5656;\n    float2 param_12 = _5660;\n    float2 param_13 = _5672 + 1.0f.xx;\n    float3 _5714 = _5669.x.xxx;\n    return lerp(lerp(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5714), lerp(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5714), _5669.y.xxx);\n}\n\nfloat3 fa_xm_sample(float2 uv, float lod)\n{\n    float _5733 = max(_650_fa_tr_b.w - 1.0f, 0.0f);\n    float _5737 = clamp(lod, 0.0f, _5733);\n    int _5741 = int(floor(_5737));\n    int param = _5741;\n    float2 param_1 = uv;\n    float3 c = fa_xm_level(param, param_1);\n    float _5751 = float(_5741);\n    float _5752 = _5737 - _5751;\n    bool _5754 = _5752 > 0.001000000047497451305389404296875f;\n    bool _5761;\n    if (_5754)\n    {\n        _5761 = _5751 < _5733;\n    }\n    else\n    {\n        _5761 = _5754;\n    }\n    if (_5761)\n    {\n        int param_2 = _5741 + 1;\n        float2 param_3 = uv;\n        c = lerp(c, fa_xm_level(param_2, param_3), _5752.xxx);\n    }\n    return c;\n}\n\nfloat3 fa_transmitted(Surface s, float3 n, float3 v, float roughness, float3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _5787 = fa_env_brdf(param, param_1);\n    float3 _5811 = ((1.0f.xxx - clamp((f0 * _5787.x) + (f90.xxx * _5787.y), 0.0f.xxx, 1.0f.xxx)) * s.albedo) * (tr * keep);\n    float3 through = _5811;\n    float _5817 = max(s.thickness, 0.0f);\n    bool _5822 = _5817 > 0.0f;\n    if ((s.attenuation_distance > 0.0f) && _5822)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, 9.9999997473787516355514526367188e-05f.xxx, 1.0f.xxx))) / s.attenuation_distance.xxx)) * _5817);\n    }\n    bool _5847 = _650_fa_tr_a.w > 1.5f;\n    bool _5853;\n    if (_5847)\n    {\n        _5853 = _650_fa_tr_a.w < 2.5f;\n    }\n    else\n    {\n        _5853 = _5847;\n    }\n    bool _5860;\n    if (!_5853)\n    {\n        _5860 = _650_fa_tr_a.w < 0.5f;\n    }\n    else\n    {\n        _5860 = _5853;\n    }\n    if (_5860)\n    {\n        blend = clamp(dot(through, 0.3333333432674407958984375f.xxx), 0.0f, 0.980000019073486328125f);\n        return 0.0f.xxx;\n    }\n    float4 _5875 = float4(fa_world_pos, 1.0f);\n    float _5880 = dot(_650_fa_ct_vpw, _5875);\n    float2 uv0 = 0.5f.xx;\n    if (_5880 > 9.9999997473787516355514526367188e-05f)\n    {\n        float2 _5898 = float2(dot(_650_fa_ct_vpx, _5875), dot(_650_fa_ct_vpy, _5875)) / _5880.xx;\n        float _5906;\n        if (_650_fa_ct_a.y > 0.5f)\n        {\n            _5906 = (_5898.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5906 = 0.5f - (_5898.y * 0.5f);\n        }\n        uv0 = float2((_5898.x * 0.5f) + 0.5f, _5906);\n    }\n    if (_650_fa_tr_a.w > 2.5f)\n    {\n        int param_2 = 0;\n        float2 _5927 = fa_xm_size(param_2);\n        float2 _5935 = floor(clamp(uv0, 0.0f.xx, 0.99989998340606689453125f.xx) * _5927);\n        if (fa_screen_tex.Load(int3(int2(_5935), 0)).w > 0.5f)\n        {\n            int _5955 = int(floor((clamp(roughness, 0.0f, 1.0f) * 2.0f) + 0.5f));\n            float3 acc = 0.0f.xxx;\n            float cnt = 0.0f;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _5978 = abs(dx) > _5955;\n                    bool _5986;\n                    if (!_5978)\n                    {\n                        _5986 = abs(dy) > _5955;\n                    }\n                    else\n                    {\n                        _5986 = _5978;\n                    }\n                    if (_5986)\n                    {\n                        continue;\n                    }\n                    float4 _6007 = fa_screen_tex.Load(int3(int2(clamp(_5935 + float2(float(dx), float(dy)), 0.0f.xx, _5927 - 1.0f.xx)), 0));\n                    if (_6007.w > 0.5f)\n                    {\n                        acc += _6007.xyz;\n                        cnt += 1.0f;\n                    }\n                }\n            }\n            return _5811 * (acc / max(cnt, 1.0f).xxx);\n        }\n    }\n    float2 uv = uv0;\n    if (_5822)\n    {\n        float4 _6055 = float4(fa_world_pos + (refract(-v, n, 1.0f / max(s.ior, 1.0f)) * _5817), 1.0f);\n        float _6060 = dot(_650_fa_ct_vpw, _6055);\n        uv = 0.5f.xx;\n        if (_6060 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _6077 = float2(dot(_650_fa_ct_vpx, _6055), dot(_650_fa_ct_vpy, _6055)) / _6060.xx;\n            float _6085;\n            if (_650_fa_ct_a.y > 0.5f)\n            {\n                _6085 = (_6077.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _6085 = 0.5f - (_6077.y * 0.5f);\n            }\n            uv = float2((_6077.x * 0.5f) + 0.5f, _6085);\n        }\n    }\n    float2 param_3 = clamp(uv, 0.0f.xx, 1.0f.xx);\n    float param_4 = (clamp(roughness, 0.0f, 1.0f) * clamp((2.0f * s.ior) - 2.0f, 0.0f, 1.0f)) * max(_650_fa_tr_b.w - 1.0f, 0.0f);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2312_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3271 = int(_2312_fa_shadow_cfg.x + 0.5f);\n    float _3281 = dot(world - _2312_fa_shadow_eye.xyz, _2312_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3286 = _3271 > 0;\n    bool _3295;\n    if (_3286)\n    {\n        int param = _3271 - 1;\n        _3295 = _3281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3295 = _3286;\n    }\n    if (_3295)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3301 = _3271 > 1;\n        bool _3308;\n        if (_3301)\n        {\n            _3308 = _3281 > _2312_fa_shadow_split.x;\n        }\n        else\n        {\n            _3308 = _3301;\n        }\n        if (_3308)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3314 = _3271 > 2;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3281 > _2312_fa_shadow_split.y;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3327 = _3271 > 3;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3281 > _2312_fa_shadow_split.z;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _9063 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9063 = -_9063;\n    }\n    float3 _8356 = normalize(_650_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _9076 = { fa_world_pos, _9063, fa_world_tangent, fa_uv, fa_vertex_color, _8356, gl_FrontFacing };\n    SurfaceInput param_1 = _9076;\n    Surface _8364 = fa_standard_surface(param_1);\n    float3 _9094 = _8364.albedo;\n    float _9095 = _8364.alpha;\n    float3 _9096 = _8364.normal;\n    float _9097 = _8364.metallic;\n    float _9098 = _8364.roughness;\n    float _9099 = _8364.occlusion;\n    float3 _9100 = _8364.emission;\n    float _9101 = _8364.clearcoat;\n    float _9102 = _8364.clearcoat_roughness;\n    float3 _9103 = _8364.sheen_color;\n    float _9104 = _8364.sheen_roughness;\n    float _9105 = _8364.anisotropy;\n    float _9106 = _8364.anisotropy_rotation;\n    float _9107 = _8364.specular;\n    float _9108 = _8364.ior;\n    float3 _9109 = _8364.specular_color;\n    float _9110 = _8364.transmission;\n    float _9111 = _8364.thickness;\n    float3 _9112 = _8364.attenuation_color;\n    float _9113 = _8364.attenuation_distance;\n    SurfaceInput _9084 = { fa_world_pos, _9063, fa_world_tangent, fa_uv, fa_vertex_color, _8356, gl_FrontFacing };\n    SurfaceInput param_2 = _9084;\n    Surface param_3 = _8364;\n    surface(param_2, param_3);\n    _9094 = param_3.albedo;\n    _9095 = param_3.alpha;\n    _9096 = param_3.normal;\n    _9097 = param_3.metallic;\n    _9098 = param_3.roughness;\n    _9099 = param_3.occlusion;\n    _9100 = param_3.emission;\n    _9101 = param_3.clearcoat;\n    _9102 = param_3.clearcoat_roughness;\n    _9103 = param_3.sheen_color;\n    _9104 = param_3.sheen_roughness;\n    _9105 = param_3.anisotropy;\n    _9106 = param_3.anisotropy_rotation;\n    _9107 = param_3.specular;\n    _9108 = param_3.ior;\n    _9109 = param_3.specular_color;\n    _9110 = param_3.transmission;\n    _9111 = param_3.thickness;\n    _9112 = param_3.attenuation_color;\n    _9113 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _9063;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9094 = param_6;\n    _9096 = param_7;\n    float fa_tr_blend = 0.0f;\n    float3 result;\n    if (_650_fa_emissive.w > 0.5f)\n    {\n        result = _9094;\n    }\n    else\n    {\n        float3 _8404 = normalize(_9096);\n        float _8411 = clamp(_9097, 0.0f, 1.0f);\n        float _8415 = clamp(_9098, 0.0500000007450580596923828125f, 1.0f);\n        float _8419 = _8415 * _8415;\n        float _8423 = _8419 * _8419;\n        float _8428 = max(dot(_8404, _8356), 9.9999997473787516355514526367188e-05f);\n        float _8434 = 1.0f - _8411;\n        float _8435 = clamp(_9110, 0.0f, 1.0f) * _8434;\n        float3 _8444 = (_9094 * _8434) * (1.0f - _8435);\n        float3 _8451 = lerp(0.039999999105930328369140625f.xxx, _9094, _8411.xxx);\n        float3 f0 = _8451;\n        SurfaceInput _9092 = { fa_world_pos, _9063, fa_world_tangent, fa_uv, fa_vertex_color, _8356, gl_FrontFacing };\n        SurfaceInput param_8 = _9092;\n        Surface _9195 = { _9094, _9095, _9096, _9097, _9098, _9099, _9100, _9101, _9102, _9103, _9104, _9105, _9106, _9107, _9108, _9109, _9110, _9111, _9112, _9113 };\n        Surface param_9 = _9195;\n        float3 param_10 = _8404;\n        float3 param_11 = _8356;\n        float param_12 = _8411;\n        float param_13 = _8415;\n        float3 param_14 = _8451;\n        FaLayers _8467 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _8404;\n        float3 lit = (fa_indirect_diffuse(param_15) * _8444) * _9099;\n        if (_8467.on)\n        {\n            lit *= _8467.base_scale;\n        }\n        int _8489 = fa_cl_ndir + fa_cl_local;\n        float _8554;\n        for (int ln = 0; ln < _8489; ln++)\n        {\n            int param_16 = ln;\n            int _8502 = fa_cl_light(param_16);\n            int param_17 = _8502;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _8502;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _9063;\n            LightSample _8518 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8526 = max(dot(_8404, _8518.direction), 0.0f);\n            float _8532 = _8518.attenuation * _8518.shadow;\n            float3 _8537 = normalize(_8518.direction + _8356);\n            float _8542 = max(dot(_8404, _8537), 0.0f);\n            float _8547 = max(dot(_8356, _8537), 0.0f);\n            if (fa_light_is_area)\n            {\n                if (_8467.on)\n                {\n                    _8554 = _8467.f90;\n                }\n                else\n                {\n                    _8554 = 1.0f;\n                }\n                int param_21 = _8502;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _8404;\n                float3 param_24 = _8356;\n                float3 param_25 = _8444;\n                float3 param_26 = f0;\n                float param_27 = _8554;\n                float param_28 = _8415;\n                float param_29 = _8428;\n                float param_30 = _8532;\n                float3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8467.on)\n                {\n                    FaLayers param_31 = _8467;\n                    float3 param_32 = area;\n                    int param_33 = _8502;\n                    float3 param_34 = _8404;\n                    float3 param_35 = _8356;\n                    float3 param_36 = _8518.direction;\n                    float param_37 = _8428;\n                    float param_38 = _8532;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8467.on)\n                {\n                    FaLayers param_39 = _8467;\n                    float3 param_40 = _8444;\n                    float3 param_41 = f0;\n                    float3 param_42 = _8404;\n                    float3 param_43 = _8356;\n                    float3 param_44 = _8518.direction;\n                    float3 param_45 = _8537;\n                    float param_46 = _8526;\n                    float param_47 = _8428;\n                    float param_48 = _8542;\n                    float param_49 = _8547;\n                    float param_50 = _8419;\n                    float param_51 = _8423;\n                    int param_52 = _8502;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8532));\n                }\n                else\n                {\n                    float _8656 = ((_8542 * _8542) * (_8423 - 1.0f)) + 1.0f;\n                    int param_53 = _8502;\n                    lit += (((_8444 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _8547, 5.0f))) * (((_8423 / ((3.1415927410125732421875f * _8656) * _8656)) * (0.5f / max(lerp((2.0f * _8526) * _8428, _8526 + _8428, _8419), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _8526))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8526 * _8532));\n                }\n            }\n        }\n        if (_8467.on)\n        {\n            FaLayers param_54 = _8467;\n            float3 param_55 = _8404;\n            float3 param_56 = _8356;\n            float3 param_57 = f0;\n            float param_58 = _8415;\n            float param_59 = _9099;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            float3 param_60 = _8404;\n            float3 param_61 = _8356;\n            float3 param_62 = f0;\n            float param_63 = _8415;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9099);\n        }\n        if (_8435 > 0.0f)\n        {\n            float _8754;\n            if (_8467.on)\n            {\n                _8754 = _8467.f90;\n            }\n            else\n            {\n                _8754 = 1.0f;\n            }\n            float _8762;\n            if (_8467.on)\n            {\n                _8762 = _8467.base_scale;\n            }\n            else\n            {\n                _8762 = 1.0f;\n            }\n            Surface _9216 = { _9094, _9095, _9096, _9097, _9098, _9099, _9100, _9101, _9102, _9103, _9104, _9105, _9106, _9107, _9108, _9109, _9110, _9111, _9112, _9113 };\n            Surface param_64 = _9216;\n            float3 param_65 = _8404;\n            float3 param_66 = _8356;\n            float param_67 = _8415;\n            float3 param_68 = f0;\n            float param_69 = _8754;\n            float param_70 = _8762;\n            float param_71 = _8435;\n            float param_72 = fa_tr_blend;\n            float3 _8786 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8786;\n        }\n        result = lit;\n    }\n    float3 _8793 = result;\n    float3 _8794 = _8793 + _9100;\n    result = _8794;\n    float3 param_73 = _8794;\n    float3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8803 = _650_fa_fog.w > 0.0f;\n    bool _8810;\n    if (!_8803)\n    {\n        _8810 = _650_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _8810 = _8803;\n    }\n    if (_8810)\n    {\n        float3 _8819 = fa_world_pos - _650_fa_camera_pos.xyz;\n        float _8825 = dot(_8819, _650_fa_fog_c.xyz);\n        bool _8829 = _650_fa_fog_c.w > 0.5f;\n        float _8830;\n        if (_8829)\n        {\n            _8830 = _8825;\n        }\n        else\n        {\n            _8830 = length(_8819);\n        }\n        float _8842 = _8830 - _650_fa_fog_b.x;\n        if (_8842 > 0.0f)\n        {\n            float _8851 = _650_fa_fog.w * _8842;\n            float tau = _8851 * _8851;\n            if (_650_fa_fog_b.y > 0.0f)\n            {\n                float _8867;\n                if (_8829)\n                {\n                    _8867 = fa_world_pos.y - (_650_fa_fog_c.y * _8825);\n                }\n                else\n                {\n                    _8867 = _650_fa_camera_pos.y;\n                }\n                float _8888 = lerp(_8867, fa_world_pos.y, clamp(_650_fa_fog_b.x / _8830, 0.0f, 1.0f));\n                float _8892 = fa_world_pos.y - _8888;\n                float _8897 = _8888 - _650_fa_fog_b.z;\n                float _8902 = fa_world_pos.y - _650_fa_fog_b.z;\n                bool _8905 = _8897 <= 0.0f;\n                bool _8906 = !_8905;\n                bool _8912;\n                if (_8906)\n                {\n                    _8912 = _650_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8912 = _8905;\n                }\n                float _8913;\n                if (_8912)\n                {\n                    _8913 = _650_fa_fog_b.y;\n                }\n                else\n                {\n                    _8913 = _650_fa_fog_b.y * exp(-min(_650_fa_fog_b.w * _8897, 80.0f));\n                }\n                bool _8940;\n                if (_8906)\n                {\n                    _8940 = _650_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8940 = _8905;\n                }\n                float _8941;\n                if (_8940)\n                {\n                    _8941 = _650_fa_fog_b.y * _8897;\n                }\n                else\n                {\n                    _8941 = (_650_fa_fog_b.y * (1.0f - exp(-min(_650_fa_fog_b.w * _8897, 80.0f)))) / _650_fa_fog_b.w;\n                }\n                bool _8966 = _8902 <= 0.0f;\n                bool _8973;\n                if (!_8966)\n                {\n                    _8973 = _650_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _8973 = _8966;\n                }\n                float _8974;\n                if (_8973)\n                {\n                    _8974 = _650_fa_fog_b.y * _8902;\n                }\n                else\n                {\n                    _8974 = (_650_fa_fog_b.y * (1.0f - exp(-min(_650_fa_fog_b.w * _8902, 80.0f)))) / _650_fa_fog_b.w;\n                }\n                float _9001;\n                if (abs(_8892) < 0.001000000047497451305389404296875f)\n                {\n                    _9001 = _8913;\n                }\n                else\n                {\n                    _9001 = (_8974 - _8941) / _8892;\n                }\n                tau += (_8842 * max(_9001, 0.0f));\n            }\n            result = lerp(result, _650_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    if (fa_tr_blend > 0.0f)\n    {\n        float _9037 = 1.0f - fa_tr_blend;\n        result /= _9037.xxx;\n        _9095 *= _9037;\n    }\n    fa_frag_color = float4(result, _9095);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_650",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2312",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _56_fa_view_proj : packoffset(c0);\n    row_major float4x4 _56_fa_light_vp : packoffset(c4);\n    float4 _56_fa_uv_scale : packoffset(c8);\n    float4 _56_fa_time : packoffset(c9);\n    float4 _56_fa_lm_so : packoffset(c10);\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _217_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _217_fa_vel_prev_vp : packoffset(c4);\n    float4 _217_fa_vel_on : packoffset(c8);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _382_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4 fa_time_now()\n{\n    return _56_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _144 = cross(model[1].xyz, model[2].xyz);\n    float _147 = (dot(model[0].xyz, _144) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _423 = { mul(float4(position, 1.0f), model).xyz, (((_144 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _147, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _147), texcoord0 * _56_fa_uv_scale.xy, color, position };\n    return _423;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _82 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _97;\n    if (!_82)\n    {\n        _97 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _97 = _82;\n    }\n    if (_97)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nfloat4x4 fa_prev_model()\n{\n    return float4x4(float4(1.0f, 0.0f, 0.0f, 0.0f), float4(0.0f, 1.0f, 0.0f, 0.0f), float4(0.0f, 0.0f, 1.0f, 0.0f), float4(0.0f, 0.0f, 0.0f, 1.0f));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _221;\n    if (has_prev)\n    {\n        _221 = _217_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _221 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _251 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_251, _56_fa_light_vp).z;\n    fa_pre_r0 = float3(_56_fa_light_vp[0].x, _56_fa_light_vp[1].x, _56_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_56_fa_light_vp[0].y, _56_fa_light_vp[1].y, _56_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_56_fa_light_vp[0].z, _56_fa_light_vp[1].z, _56_fa_light_vp[2].z);\n    gl_Position = mul(_251, _56_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_221)\n    {\n        fa_vtime.x = _217_fa_vel_on.y;\n        float4x4 param_7 = fa_prev_model();\n        float3 param_8 = position;\n        float3 param_9 = normal;\n        float4 param_10 = tangent;\n        float2 param_11 = texcoord0;\n        float4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = float3(mul(_251, _217_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4(param_13.world_pos, 1.0f), _217_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4x4 param = _382_fa_base_model;\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    bool param_6 = false;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _232_fa_camera_pos : packoffset(c0);\n    float4 _232_fa_ambient : packoffset(c1);\n    float4 _232_fa_base_color : packoffset(c2);\n    float4 _232_fa_emissive : packoffset(c3);\n    float4 _232_fa_model_emissive : packoffset(c4);\n    float4 _232_fa_pbr : packoffset(c5);\n    float4 _232_fa_maps : packoffset(c6);\n    float4 _232_fa_fog : packoffset(c7);\n    float4 _232_fa_fog_b : packoffset(c8);\n    float4 _232_fa_fog_c : packoffset(c9);\n    float4 _232_fa_counts : packoffset(c10);\n    float4 _232_fa_env_sky : packoffset(c11);\n    float4 _232_fa_env_horizon : packoffset(c12);\n    float4 _232_fa_time : packoffset(c13);\n    float4 _232_fa_cl_vpx : packoffset(c14);\n    float4 _232_fa_cl_vpy : packoffset(c15);\n    float4 _232_fa_cl_vpw : packoffset(c16);\n    float4 _232_fa_cl_fwd : packoffset(c17);\n    float4 _232_fa_cl_grid : packoffset(c18);\n    float4 _232_fa_cl_info : packoffset(c19);\n    float4 _232_fa_layers_a : packoffset(c20);\n    float4 _232_fa_layers_b : packoffset(c21);\n    float4 _232_fa_layers_c : packoffset(c22);\n    float4 _232_fa_layers_d : packoffset(c23);\n    float4 _232_fa_ct_a : packoffset(c24);\n    float4 _232_fa_ct_b : packoffset(c25);\n    float4 _232_fa_ct_vpx : packoffset(c26);\n    float4 _232_fa_ct_vpy : packoffset(c27);\n    float4 _232_fa_ct_vpw : packoffset(c28);\n    float4 _232_fa_ct_fwd : packoffset(c29);\n    float4 _232_fa_tr_a : packoffset(c30);\n    float4 _232_fa_tr_b : packoffset(c31);\n    float4 _232_fa_probe_sh[9] : packoffset(c32);\n    float4 _232_fa_atlas : packoffset(c41);\n    float4 _232_fa_rpa_tile : packoffset(c42);\n    float4 _232_fa_rpa_pos : packoffset(c43);\n    float4 _232_fa_rpa_bx : packoffset(c44);\n    float4 _232_fa_rpa_by : packoffset(c45);\n    float4 _232_fa_rpa_bz : packoffset(c46);\n    float4 _232_fa_rpb_tile : packoffset(c47);\n    float4 _232_fa_rpb_pos : packoffset(c48);\n    float4 _232_fa_rpb_bx : packoffset(c49);\n    float4 _232_fa_rpb_by : packoffset(c50);\n    float4 _232_fa_rpb_bz : packoffset(c51);\n    float4 _232_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w);\n    float param = _232_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _247 = fa_tex_fix(param_2, param_3);\n    float4 _859 = base_t;\n    _859.x = _247.x;\n    _859.y = _247.y;\n    _859.z = _247.z;\n    base_t = _859;\n    float4 _262 = (_859 * _232_fa_base_color) * i.vertex_color;\n    float3 _814 = i.world_normal;\n    if (_232_fa_maps.z > 0.5f)\n    {\n        float param_4 = _232_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _297 = fa_tex_fix(param_6, param_7);\n        float3 _301 = (_297 * 2.0f) - 1.0f.xxx;\n        float2 _306 = _301.xy * _232_fa_maps.x;\n        float3 _867 = _301;\n        _867.x = _306.x;\n        _867.y = _306.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _867;\n        _814 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w);\n    float param_10 = _232_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _337 = fa_tex_fix(param_12, param_13);\n    float4 _870 = mrt;\n    _870.x = _337.x;\n    _870.y = _337.y;\n    _870.z = _337.z;\n    mrt = _870;\n    float4 _369 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w);\n    float param_14 = _232_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = _232_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _413 = fa_tex_fix(param_20, param_21);\n    float _819 = _232_fa_layers_a.x;\n    float _820 = _232_fa_layers_a.y;\n    float _823 = _232_fa_layers_a.z;\n    float _822 = _232_fa_layers_b.w;\n    float _825 = _232_fa_layers_c.x;\n    if (_232_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_232_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _819 *= _381.y;\n            _820 *= _381.z;\n            _822 *= _369.w;\n        }\n        if (_232_fa_layers_c.z > 1.5f)\n        {\n            _823 *= mrt.x;\n            _825 *= mrt.w;\n        }\n    }\n    Surface _852 = { _262.xyz, _262.w, _814, clamp(_232_fa_pbr.x * _337.z, 0.0f, 1.0f), clamp(_232_fa_pbr.y * _337.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_232_fa_maps.y * (_381.x - 1.0f)), _232_fa_emissive.xyz + (_232_fa_model_emissive.xyz * _413), _819, _820, _232_fa_layers_b.xyz, _822, _823, _232_fa_layers_a.w, _825, _232_fa_layers_c.y, _232_fa_layers_d.xyz, _232_fa_tr_a.x, _232_fa_tr_a.y, _232_fa_tr_b.xyz, _232_fa_tr_a.z };\n    return _852;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _709 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _709 = -_709;\n    }\n    float3 _565 = normalize(_232_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _722 = { fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing };\n    SurfaceInput param = _722;\n    SurfaceInput _730 = { fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing };\n    SurfaceInput param_1 = _730;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _580 = normalize(param_2.normal);\n    float3 _595 = normalize(float3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    float2 e = _595.xy / ((abs(_595.x) + abs(_595.y)) + abs(_607)).xx;\n    if (_607 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
            "inst_name": "_56",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_217",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_382",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _61_fa_view_proj : packoffset(c0);\n    row_major float4x4 _61_fa_light_vp : packoffset(c4);\n    float4 _61_fa_uv_scale : packoffset(c8);\n    float4 _61_fa_time : packoffset(c9);\n    float4 _61_fa_lm_so : packoffset(c10);\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer fa_skin : register(b3)\n{\n    float4 _245_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _328_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _328_fa_vel_prev_vp : packoffset(c4);\n    float4 _328_fa_vel_on : packoffset(c8);\n};\n\ncbuffer fa_inst_base : register(b6)\n{\n    row_major float4x4 _493_fa_base_model : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _236 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_245_fa_joint_rows[_236] * weights[i]);\n        r1 += (_245_fa_joint_rows[_236 + 1] * weights[i]);\n        r2 += (_245_fa_joint_rows[_236 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_time_now()\n{\n    return _61_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _149 = cross(model[1].xyz, model[2].xyz);\n    float _152 = (dot(model[0].xyz, _149) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _548 = { mul(float4(position, 1.0f), model).xyz, (((_149 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _152, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _152), texcoord0 * _61_fa_uv_scale.xy, color, position };\n    return _548;\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _87 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w < 0.5f;\n    bool _102;\n    if (!_87)\n    {\n        _102 = asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f);\n    }\n    else\n    {\n        _102 = _87;\n    }\n    if (_102)\n    {\n        v.world_pos = 1000000000.0f.xxx;\n        return;\n    }\n    v.world_pos += asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xyz;\n    v.color = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 16));\n}\n\nfloat4x4 fa_prev_model()\n{\n    return float4x4(float4(1.0f, 0.0f, 0.0f, 0.0f), float4(0.0f, 1.0f, 0.0f, 0.0f), float4(0.0f, 0.0f, 1.0f, 0.0f), float4(0.0f, 0.0f, 0.0f, 1.0f));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _332;\n    if (has_prev)\n    {\n        _332 = _328_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _332 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _362 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_362, _61_fa_light_vp).z;\n    fa_pre_r0 = float3(_61_fa_light_vp[0].x, _61_fa_light_vp[1].x, _61_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_61_fa_light_vp[0].y, _61_fa_light_vp[1].y, _61_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_61_fa_light_vp[0].z, _61_fa_light_vp[1].z, _61_fa_light_vp[2].z);\n    gl_Position = mul(_362, _61_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_332)\n    {\n        fa_vtime.x = _328_fa_vel_on.y;\n        float4x4 param_7 = fa_prev_model();\n        float3 param_8 = position;\n        float3 param_9 = normal;\n        float4 param_10 = tangent;\n        float2 param_11 = texcoord0;\n        float4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = float3(mul(_362, _328_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4(param_13.world_pos, 1.0f), _328_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), _493_fa_base_model);\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    bool param_8 = false;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer points : register(t5);\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _232_fa_camera_pos : packoffset(c0);\n    float4 _232_fa_ambient : packoffset(c1);\n    float4 _232_fa_base_color : packoffset(c2);\n    float4 _232_fa_emissive : packoffset(c3);\n    float4 _232_fa_model_emissive : packoffset(c4);\n    float4 _232_fa_pbr : packoffset(c5);\n    float4 _232_fa_maps : packoffset(c6);\n    float4 _232_fa_fog : packoffset(c7);\n    float4 _232_fa_fog_b : packoffset(c8);\n    float4 _232_fa_fog_c : packoffset(c9);\n    float4 _232_fa_counts : packoffset(c10);\n    float4 _232_fa_env_sky : packoffset(c11);\n    float4 _232_fa_env_horizon : packoffset(c12);\n    float4 _232_fa_time : packoffset(c13);\n    float4 _232_fa_cl_vpx : packoffset(c14);\n    float4 _232_fa_cl_vpy : packoffset(c15);\n    float4 _232_fa_cl_vpw : packoffset(c16);\n    float4 _232_fa_cl_fwd : packoffset(c17);\n    float4 _232_fa_cl_grid : packoffset(c18);\n    float4 _232_fa_cl_info : packoffset(c19);\n    float4 _232_fa_layers_a : packoffset(c20);\n    float4 _232_fa_layers_b : packoffset(c21);\n    float4 _232_fa_layers_c : packoffset(c22);\n    float4 _232_fa_layers_d : packoffset(c23);\n    float4 _232_fa_ct_a : packoffset(c24);\n    float4 _232_fa_ct_b : packoffset(c25);\n    float4 _232_fa_ct_vpx : packoffset(c26);\n    float4 _232_fa_ct_vpy : packoffset(c27);\n    float4 _232_fa_ct_vpw : packoffset(c28);\n    float4 _232_fa_ct_fwd : packoffset(c29);\n    float4 _232_fa_tr_a : packoffset(c30);\n    float4 _232_fa_tr_b : packoffset(c31);\n    float4 _232_fa_probe_sh[9] : packoffset(c32);\n    float4 _232_fa_atlas : packoffset(c41);\n    float4 _232_fa_rpa_tile : packoffset(c42);\n    float4 _232_fa_rpa_pos : packoffset(c43);\n    float4 _232_fa_rpa_bx : packoffset(c44);\n    float4 _232_fa_rpa_by : packoffset(c45);\n    float4 _232_fa_rpa_bz : packoffset(c46);\n    float4 _232_fa_rpb_tile : packoffset(c47);\n    float4 _232_fa_rpb_pos : packoffset(c48);\n    float4 _232_fa_rpb_bx : packoffset(c49);\n    float4 _232_fa_rpb_by : packoffset(c50);\n    float4 _232_fa_rpb_bz : packoffset(c51);\n    float4 _232_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w);\n    float param = _232_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _247 = fa_tex_fix(param_2, param_3);\n    float4 _859 = base_t;\n    _859.x = _247.x;\n    _859.y = _247.y;\n    _859.z = _247.z;\n    base_t = _859;\n    float4 _262 = (_859 * _232_fa_base_color) * i.vertex_color;\n    float3 _814 = i.world_normal;\n    if (_232_fa_maps.z > 0.5f)\n    {\n        float param_4 = _232_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _297 = fa_tex_fix(param_6, param_7);\n        float3 _301 = (_297 * 2.0f) - 1.0f.xxx;\n        float2 _306 = _301.xy * _232_fa_maps.x;\n        float3 _867 = _301;\n        _867.x = _306.x;\n        _867.y = _306.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _867;\n        _814 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w);\n    float param_10 = _232_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _337 = fa_tex_fix(param_12, param_13);\n    float4 _870 = mrt;\n    _870.x = _337.x;\n    _870.y = _337.y;\n    _870.z = _337.z;\n    mrt = _870;\n    float4 _369 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w);\n    float param_14 = _232_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = _232_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _232_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _413 = fa_tex_fix(param_20, param_21);\n    float _819 = _232_fa_layers_a.x;\n    float _820 = _232_fa_layers_a.y;\n    float _823 = _232_fa_layers_a.z;\n    float _822 = _232_fa_layers_b.w;\n    float _825 = _232_fa_layers_c.x;\n    if (_232_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_232_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _819 *= _381.y;\n            _820 *= _381.z;\n            _822 *= _369.w;\n        }\n        if (_232_fa_layers_c.z > 1.5f)\n        {\n            _823 *= mrt.x;\n            _825 *= mrt.w;\n        }\n    }\n    Surface _852 = { _262.xyz, _262.w, _814, clamp(_232_fa_pbr.x * _337.z, 0.0f, 1.0f), clamp(_232_fa_pbr.y * _337.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_232_fa_maps.y * (_381.x - 1.0f)), _232_fa_emissive.xyz + (_232_fa_model_emissive.xyz * _413), _819, _820, _232_fa_layers_b.xyz, _822, _823, _232_fa_layers_a.w, _825, _232_fa_layers_c.y, _232_fa_layers_d.xyz, _232_fa_tr_a.x, _232_fa_tr_a.y, _232_fa_tr_b.xyz, _232_fa_tr_a.z };\n    return _852;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * asfloat(points.Load(28)));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _709 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _709 = -_709;\n    }\n    float3 _565 = normalize(_232_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _722 = { fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing };\n    SurfaceInput param = _722;\n    SurfaceInput _730 = { fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing };\n    SurfaceInput param_1 = _730;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _580 = normalize(param_2.normal);\n    float3 _595 = normalize(float3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    float2 e = _595.xy / ((abs(_595.x) + abs(_595.y)) + abs(_607)).xx;\n    if (_607 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
            "inst_name": "_61",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_245",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_328",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_493",
            "hlsl_register_b_n": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
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
